import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.resetTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => ResponsiveBody(
            child: ListView(children: [
              const SizedBox(height: 16),
              Text(l.resetBody, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline_rounded)),
              ),
              const SizedBox(height: 16),
              if (state.resetEmailSent)
                Semantics(
                  liveRegion: true,
                  child: Row(children: [
                    Icon(Icons.mark_email_read_rounded, color: StatusColors.of(context).success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sl<AppConfig>().isDemo ? '${l.resetSent} ${l.resetDemoNote}' : l.resetSent,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ]),
                ),
              if (state.form == AuthFormStatus.failure && state.failure != null) FailureBox(state.failure!),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.form == AuthFormStatus.submitting
                    ? null
                    : () => context.read<AuthBloc>().add(PasswordResetRequested(_email.text)),
                child: Text(l.sendResetLink),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
