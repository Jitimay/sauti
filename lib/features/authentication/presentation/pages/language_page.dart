import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';

/// Language selection. Each option is shown in its own language so users
/// can recognise it without reading the current UI language.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key, this.popOnSelect = false});
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<PreferencesCubit>().state.language;
    return Scaffold(
      appBar: popOnSelect ? AppBar(title: Text(context.l10n.languageSetting)) : null,
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(children: [
            const SizedBox(height: 32),
            if (!popOnSelect) const Align(alignment: Alignment.centerLeft, child: SautiWordmark()),
            const SizedBox(height: 32),
            Semantics(header: true, child: Text(context.l10n.languageTitle, style: Theme.of(context).textTheme.headlineMedium)),
            const SizedBox(height: 8),
            Text(context.l10n.languageSubtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            for (final lang in AppLanguage.values) ...[
              _LanguageTile(
                language: lang,
                selected: lang == current,
                onTap: () async {
                  await context.read<PreferencesCubit>().setLanguage(lang);
                  if (popOnSelect && context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
            ],
            if (current == AppLanguage.kirundi)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(context.l10n.kirundiDraftNote, style: Theme.of(context).textTheme.bodySmall),
              ),
          ]),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language, required this.selected, required this.onTap});
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: language.nativeName,
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? scheme.primary : scheme.outline, width: selected ? 2.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.surfaceContainer, shape: BoxShape.circle),
                child: Text(language.code.toUpperCase(), style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(language.nativeName, style: Theme.of(context).textTheme.titleLarge)),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outline, size: 28),
            ]),
          ),
        ),
      ),
    );
  }
}
