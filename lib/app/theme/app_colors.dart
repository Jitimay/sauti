import 'package:material_ui/material_ui.dart';

/// Sauti palette. All text/background pairs meet WCAG AA (≥ 4.5:1) on both the
/// warm canvas and white surfaces; the high-contrast set targets AAA (≥ 7:1).
///
/// Direction: calm and warm rather than "fintech blue". A deep lake navy
/// (Tanganyika at dusk) carries trust; a sunrise amber marks the voice and
/// anything that needs the user's attention; the canvas is a warm paper tone
/// that is easier on low-vision eyes than pure white.
abstract final class AppColors {
  // Brand
  static const navy = Color(0xFF0F2A4A);
  static const navyDeep = Color(0xFF0A1D35);
  static const navyLight = Color(0xFF1F4470);
  static const navyTint = Color(0xFFE4ECF6);

  /// Sunrise amber: the voice, the mark, attention.
  static const amber = Color(0xFFF0A93B);
  static const amberSoft = Color(0xFFFCEFD9);
  static const amberDeep = Color(0xFF8A5300); // text-safe on white (5.3:1)

  // Neutrals (warm)
  static const ink = Color(0xFF141A23);
  static const muted = Color(0xFF545B68); // 7.0:1 on white, 6.3:1 on canvas
  static const canvas = Color(0xFFF6F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEFECE5);
  static const line = Color(0xFFE6E1D7);
  static const outline = Color(0xFFC9C3B7);

  // Status
  static const success = Color(0xFF16703A); // 6.0:1 on white
  static const successBg = Color(0xFFE4F2E8);
  static const warning = Color(0xFF9A4A00); // 6.0:1 on white
  static const warningBg = Color(0xFFFDF0DF);
  static const error = Color(0xFFB3261E); // 6.5:1 on white
  static const errorBg = Color(0xFFFBE9E7);

  // Legacy names kept for callers.
  static const background = canvas;

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
    required this.accentSoft,
    required this.muted,
    required this.line,
    required this.sunken,
    required this.isHighContrast,
  });

  final Color success, successBg, warning, warningBg, error, errorBg, accent, accentSoft, muted, line, sunken;
  final bool isHighContrast;

  static const light = StatusColors(
    success: AppColors.success,
    successBg: AppColors.successBg,
    warning: AppColors.warning,
    warningBg: AppColors.warningBg,
    error: AppColors.error,
    errorBg: AppColors.errorBg,
    accent: AppColors.amber,
    accentSoft: AppColors.amberSoft,
    muted: AppColors.muted,
    line: AppColors.line,
    sunken: AppColors.sunken,
    isHighContrast: false,
  );

  static const highContrast = StatusColors(
    success: AppColors.hcSuccess,
    successBg: AppColors.hcBackground,
    warning: AppColors.hcWarning,
    warningBg: AppColors.hcBackground,
    error: AppColors.hcError,
    errorBg: AppColors.hcBackground,
    accent: AppColors.hcAccent,
    accentSoft: AppColors.hcBackground,
    muted: AppColors.hcText,
    line: AppColors.hcText,
    sunken: AppColors.hcBackground,
    isHighContrast: true,
  );

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

/// Spacing and radius scale (4-pt grid). One place, so screens stay consistent.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
}
