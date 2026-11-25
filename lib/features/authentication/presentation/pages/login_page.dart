import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
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

  void _submit() => context.read<AuthBloc>().add(
    SignInRequested(_email.text, _password.text),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDemo = sl<AppConfig>().isDemo;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final status = StatusColors.of(context);
    final hc = status.isHighContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: hc ? Colors.black : AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final busy = state.form == AuthFormStatus.submitting;
            return Stack(
              children: [
                // Top curved header
                if (!hc)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 110,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.blueLight, AppColors.blue],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SautiAfricaLogo(size: 32, onDark: true),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l.appName,
                                style: text.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Savannah landscape at bottom
                if (!hc)
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SavannahFooter(height: 85),
                  ),
                // Main scrollable form
                Positioned.fill(
                  child: ResponsiveBody(
                    child: AutofillGroup(
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: hc ? 24 : 120,
                          bottom: hc ? 24 : 90,
                        ),
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l.signIn,
                              style: text.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: hc ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isDemo) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: status.accentSoft,
                                borderRadius: BorderRadius.circular(Radii.lg),
                                border: Border.all(
                                  color: hc
                                      ? status.accent
                                      : AppColors.amber.withValues(alpha: 0.5),
                                  width: hc ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.science_rounded,
                                          color: hc
                                              ? status.accent
                                              : AppColors.amberDeep,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l.demoCredentialsHint(
                                              DemoAuthRepository.demoEmail,
                                              DemoAuthRepository.demoPassword,
                                            ),
                                            style: text.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _email.text =
                                            DemoAuthRepository.demoEmail;
                                        _password.text =
                                            DemoAuthRepository.demoPassword;
                                      },
                                      icon: const Icon(
                                        Icons.auto_fix_high_rounded,
                                        size: 18,
                                      ),
                                      label: Text(l.useDemoCredentials),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: l.email,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _password,
                            label: l.password,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                          ),
                          if (state.form == AuthFormStatus.failure &&
                              state.failure != null) ...[
                            const SizedBox(height: 8),
                            FailureBox(state.failure!),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: hc
                                  ? status.accent
                                  : AppColors.blue,
                              foregroundColor: hc ? Colors.black : Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.lg),
                              ),
                            ),
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? Semantics(
                                    label: l.loading,
                                    child: const SizedBox.square(
                                      dimension: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    l.signIn,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    context.push(Routes.resetPassword),
                                child: Text(l.forgotPassword),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.pushReplacement(Routes.register),
                                child: Text(l.createAccount),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
