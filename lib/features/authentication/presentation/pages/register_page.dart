import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<AuthBloc>().add(RegisterRequested(_name.text, _email.text, _password.text));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.registerTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final busy = state.form == AuthFormStatus.submitting;
            return ResponsiveBody(
              child: AutofillGroup(
                child: ListView(children: [
                  const SizedBox(height: 16),
                  if (sl<AppConfig>().isDemo) ...[
                    Text(l.registerDemoNote, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l.fullName, prefixIcon: const Icon(Icons.person_outline_rounded)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.mail_outline_rounded)),
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _password,
                    label: l.password,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Text(l.passwordRules, style: Theme.of(context).textTheme.bodySmall),
                  if (state.form == AuthFormStatus.failure && state.failure != null) ...[
                    const SizedBox(height: 16),
                    FailureBox(state.failure!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(onPressed: busy ? null : _submit, child: Text(l.createAccount)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
