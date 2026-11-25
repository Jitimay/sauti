import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _finish(BuildContext context) =>
      context.read<PreferencesCubit>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final status = StatusColors.of(context);
    final isKirundi =
        Localizations.localeOf(context).languageCode ==
        AppLanguage.kirundi.code;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
                  children: [
                    const Center(child: HeadsetAvatarHero(size: 150)),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        l.onboardingTitle1,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.onboardingBody1,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: status.sunken,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: status.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _OnboardingPoint(
                              title: l.onboardingTitle2,
                              description: l.onboardingBody2,
                            ),
                            const SizedBox(height: 16),
                            _OnboardingPoint(
                              title: l.onboardingTitle3,
                              description: l.onboardingBody3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isKirundi) ...[
                      const SizedBox(height: 16),
                      Text(l.kirundiDraftNote, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () => _finish(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(l.onboardingStart),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => _finish(context),
                        child: Text(l.onboardingSkip),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  const _OnboardingPoint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: StatusColors.of(context).accent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              const SizedBox(height: 4),
              Text(description, style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
