import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';

/// Each option is presented in its own language and applied on selection.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key, this.popOnSelect = false});
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<PreferencesCubit>().state.language;
    final l = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: popOnSelect ? AppBar(title: Text(l.languageSetting)) : null,
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.languageTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(l.languageSubtitle, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              for (final lang in AppLanguage.values) ...[
                _LanguageTile(
                  language: lang,
                  selected: lang == current,
                  onTap: () async {
                    await context.read<PreferencesCubit>().setLanguage(lang);
                    if (popOnSelect && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 14),
              ],
              if (current == AppLanguage.kirundi)
                Text(l.kirundiDraftNote, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  static const _flags = {
    AppLanguage.kirundi: '🇧🇮',
    AppLanguage.french: '🇫🇷',
    AppLanguage.english: '🇬🇧',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final borderColor = selected ? status.accent : scheme.outline;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: language.nativeName,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? status.accentSoft : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor, width: selected ? 2.0 : 1.2),
        ),
        elevation: selected ? 0 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: status.sunken,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: status.line),
                  ),
                  child: Text(
                    _flags[language]!,
                    style: const TextStyle(fontSize: 28),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    language.nativeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: borderColor,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
