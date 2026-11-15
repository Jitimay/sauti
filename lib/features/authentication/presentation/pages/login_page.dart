import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../data/repositories/demo_auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthFormReset());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<AuthBloc>().add(SignInRequested(_email.text, _password.text));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDemo = sl<AppConfig>().isDemo;
    return Scaffold(
      appBar: AppBar(title: Text(l.signIn)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final busy = state.form == AuthFormStatus.submitting;
            return ResponsiveBody(
              child: AutofillGroup(
                child: ListView(children: [
                  const SizedBox(height: 16),
                  if (isDemo) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.demoCredentialsHint(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword),
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              _email.text = DemoAuthRepository.demoEmail;
                              _password.text = DemoAuthRepository.demoPassword;
                            },
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: Text(l.useDemoCredentials),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => context.push(Routes.resetPassword), child: Text(l.forgotPassword)),
                  ),
                  if (state.form == AuthFormStatus.failure && state.failure != null) ...[
                    const SizedBox(height: 8),
                    FailureBox(state.failure!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? Semantics(label: l.loading, child: const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)))
                        : Text(l.signIn),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.pushReplacement(Routes.register), child: Text(l.createAccount)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
