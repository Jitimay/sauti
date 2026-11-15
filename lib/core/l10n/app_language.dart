/// Languages supported by Sauti's interface and agent.
enum AppLanguage {
  english('en', 'English', ['en_US', 'en_GB', 'en']),
  french('fr', 'Français', ['fr_FR', 'fr_BE', 'fr_CA', 'fr']),
  kirundi('rn', 'Ikirundi', ['rn_BI', 'rn']);

  const AppLanguage(this.code, this.nativeName, this.speechLocaleCandidates);

  /// ISO-639-1 code used for app localization.
  final String code;

  /// Name shown in the language picker (always in the language itself).
  final String nativeName;

  /// Platform locale identifiers to try, in order, for speech recognition/TTS.
  final List<String> speechLocaleCandidates;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.english);
}
