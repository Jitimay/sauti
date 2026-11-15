import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_parser.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../authentication/presentation/widgets/auth_widgets.dart';
import '../../domain/entities/transfer_stage.dart';
import '../bloc/transfer_bloc.dart';

/// Manual transfer form — the non-voice path to the same workflow.
class TransferPreparePage extends StatefulWidget {
  const TransferPreparePage({super.key, this.prefillBeneficiaryId});
  final String? prefillBeneficiaryId;

  @override
  State<TransferPreparePage> createState() => _TransferPreparePageState();
}

class _TransferPreparePageState extends State<TransferPreparePage> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _beneficiaryId;
  bool _amountError = false;

  @override
  void initState() {
    super.initState();
    _beneficiaryId = widget.prefillBeneficiaryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _review() {
    final money = MoneyParser.parse(_amount.text);
    setState(() => _amountError = money == null);
    if (money == null || _beneficiaryId == null) return;
    final bloc = context.read<TransferBloc>();
    if (bloc.state.stage != TransferStage.idle) bloc.add(const TransferCancelled());
    bloc.add(TransferDraftRequested(beneficiaryId: _beneficiaryId!, amount: money, note: _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocListener<TransferBloc, TransferState>(
      listenWhen: (a, b) => a.stage != b.stage && b.stage == TransferStage.awaitingAuthentication && b.draft != null,
      listener: (context, s) => context.push(Routes.transferConfirm),
      child: Scaffold(
        appBar: AppBar(title: Text(l.transferTitle)),
        body: Column(children: [
          const OfflineBanner(),
          Expanded(
            child: BlocBuilder<TransferBloc, TransferState>(builder: (context, s) {
              final busy = s.stage == TransferStage.drafting;
              return ResponsiveBody(
                child: ListView(children: [
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.verified_user_outlined),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.savedRecipientsOnly, style: Theme.of(context).textTheme.bodyLarge)),
                  ]),
                  const SizedBox(height: 16),
                  Semantics(header: true, child: Text(l.chooseRecipient, style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _beneficiaryId,
                    onChanged: (v) => setState(() => _beneficiaryId = v),
                    child: Column(children: [
                      for (final b in s.beneficiaries)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            value: b.id,
                            title: Text(b.name, style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text('${b.institution} · ${b.maskedAccount}'),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ,.]'))],
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: InputDecoration(
                      labelText: l.amountLabel,
                      prefixIcon: const Icon(Icons.payments_outlined),
                      errorText: _amountError ? l.failureInvalidAmount : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _note,
                    maxLength: 140,
                    decoration: InputDecoration(labelText: l.noteLabel, prefixIcon: const Icon(Icons.notes_rounded)),
                  ),
                  if (s.stage == TransferStage.failed && s.failure != null) ...[
                    const SizedBox(height: 8),
                    FailureBox(s.failure!.code),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy || _beneficiaryId == null ? null : _review,
                    child: busy ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)) : Text(l.reviewTransfer),
                  ),
                  const SizedBox(height: 24),
                ]),
              );
            }),
          ),
        ]),
      ),
    );
  }
}
