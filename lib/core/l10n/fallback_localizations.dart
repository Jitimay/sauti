import 'package:material_ui/material_ui.dart';

/// Material/Cupertino/Widgets have no Kirundi (`rn`) localizations. For those
/// framework strings only (e.g. "Back" tooltips, date pickers) we fall back
/// to French, the other official language of Burundi. Sauti's own strings are
/// fully localized in Kirundi via ARB files.
final class FallbackLocalizationsDelegate extends LocalizationsDelegate<dynamic> {
  const FallbackLocalizationsDelegate(this.inner, {this.forLanguage = 'rn', this.fallback = const Locale('fr')});

  final LocalizationsDelegate<dynamic> inner;
  final String forLanguage;
  final Locale fallback;

  @override
  bool isSupported(Locale locale) => locale.languageCode == forLanguage;

  @override
  Future<dynamic> load(Locale locale) => inner.load(fallback);

  @override
  bool shouldReload(covariant LocalizationsDelegate<dynamic> old) => false;

  @override
  Type get type => inner.type;

  static List<LocalizationsDelegate<dynamic>> forDelegates(List<LocalizationsDelegate<dynamic>> delegates) =>
      [for (final d in delegates) FallbackLocalizationsDelegate(d)];
}
