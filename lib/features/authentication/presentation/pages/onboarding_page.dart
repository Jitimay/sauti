import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';

/// Three short steps. Buttons (not swipes) move forward — swipe is optional.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<PreferencesCubit>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = [
      (Icons.record_voice_over_rounded, l.onboardingTitle1, l.onboardingBody1),
      (Icons.verified_user_rounded, l.onboardingTitle2, l.onboardingBody2),
      (Icons.accessibility_new_rounded, l.onboardingTitle3, l.onboardingBody3),
    ];
    final last = _page == steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: Text(l.onboardingSkip)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (icon, title, body) = steps[i];
                  return Semantics(
                    liveRegion: true,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                        child: Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 40),
                      Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)),
                      const SizedBox(height: 16),
                      Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    ]),
                  );
                },
              ),
            ),
            Semantics(
              label: l.onboardingStep(_page + 1, steps.length),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: i == _page ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(last ? l.onboardingStart : l.onboardingNext),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
