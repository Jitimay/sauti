import 'package:material_ui/material_ui.dart';

/// Sauti palette. All text/background pairs meet WCAG AA (≥ 4.5:1); the
/// high-contrast set targets AAA (≥ 7:1).
abstract final class AppColors {
  static const navy = Color(0xFF0B1F3A);
  static const navyLight = Color(0xFF1C3A63);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF4B5563); // 7.0:1 on white
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F5F7);
  static const outline = Color(0xFFD1D5DB);

  /// Warm accent used for the voice orb — evokes sunrise over Lake Tanganyika.
  static const amber = Color(0xFFE8A33D);
  static const amberDeep = Color(0xFF8A5300); // text-safe on white (5.3:1)

  static const success = Color(0xFF146C2E); // 6.4:1 on white
  static const successBg = Color(0xFFE6F4EA);
  static const warning = Color(0xFF9A4A00); // 6.0:1 on white
  static const warningBg = Color(0xFFFFF1E0);
  static const error = Color(0xFFB3261E); // 6.5:1 on white
  static const errorBg = Color(0xFFFDECEA);

  // High contrast
  static const hcBackground = Color(0xFF000000);
  static const hcSurface = Color(0xFF000000);
  static const hcText = Color(0xFFFFFFFF);
  static const hcAccent = Color(0xFFFFE14D); // 16:1 on black
  static const hcSuccess = Color(0xFF7CFC9A);
  static const hcWarning = Color(0xFFFFB86B);
  static const hcError = Color(0xFFFF8A80);
}

/// Semantic status colours resolved per theme.
@immutable
final class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.accent,
    required this.muted,
  });

  final Color success, successBg, warning, warningBg, error, errorBg, accent, muted;

  static const light = StatusColors(
    success: AppColors.success,
    successBg: AppColors.successBg,
    warning: AppColors.warning,
    warningBg: AppColors.warningBg,
    error: AppColors.error,
    errorBg: AppColors.errorBg,
    accent: AppColors.amber,
    muted: AppColors.muted,
  );

  static const highContrast = StatusColors(
    success: AppColors.hcSuccess,
    successBg: AppColors.hcBackground,
    warning: AppColors.hcWarning,
    warningBg: AppColors.hcBackground,
    error: AppColors.hcError,
    errorBg: AppColors.hcBackground,
    accent: AppColors.hcAccent,
    muted: AppColors.hcText,
  );

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) => t < 0.5 ? this : (other ?? this);
}
