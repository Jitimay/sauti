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

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDemo = sl<AppConfig>().isDemo;
    final submitting = context.select<AuthBloc, bool>((b) => b.state.form == AuthFormStatus.submitting);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: SautiWordmark(onDark: true)),
            const Spacer(),
            Semantics(
              header: true,
              child: Text(l.welcomeTitle,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text(l.welcomeBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 40),
            if (isDemo) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary),
                onPressed: submitting
                    ? null
                    : () => context.read<AuthBloc>().add(
                        const SignInRequested(DemoAuthRepository.demoEmail, DemoAuthRepository.demoPassword)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.tryDemo),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.5)),
              onPressed: () => context.push(Routes.login),
              child: Text(l.signIn),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => context.push(Routes.register),
              child: Text(l.createAccount),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
