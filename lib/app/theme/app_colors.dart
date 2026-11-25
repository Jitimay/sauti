import 'package:material_ui/material_ui.dart';

/// Sauti’s cobalt and navy identity, with separate semantic status colours.
abstract final class AppColors {
  // Brand — primary blue
  static const blue = Color(0xFF1A56DB);
  static const primaryBlue = blue;
  static const blueDeep = Color(0xFF1E3A8A);
  static const blueLight = Color(0xFF2563EB);
  static const blueTint = Color(0xFFEFF6FF);
  static const blueSoft = Color(0xFFDBEAFE);

  // Legacy aliases so existing code keeps compiling
  static const navy = blueDeep;
  static const navyDeep = Color(0xFF172554);
  static const navyLight = blueLight;
  static const navyTint = blueTint;

  // Accent — green (success, CTA)
  static const green = Color(0xFF16A34A);
  static const accentGreen = green;
  static const greenSoft = Color(0xFFDCFCE7);
  static const greenDeep = Color(0xFF14532D);

  // Amber — kept for DEMO banner only
  static const amber = Color(0xFFF0A93B);
  static const amberSoft = Color(0xFFFCEFD9);
  static const amberDeep = Color(0xFF8A5300);

  // Neutrals
  static const ink = Color(0xFF142238);
  static const muted = Color(0xFF526177);
  static const canvas = Color(0xFFF5F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEBF0F4);
  static const line = Color(0xFFDCE4EB);
  static const outline = Color(0xFFB5C3D0);

  // Status
  static const success = Color(0xFF166534);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFF92400E);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);

  // Legacy
  static const background = canvas;

  // High contrast
  static const hcBackground = Color(0xFF000000);
  static const hcSurface = Color(0xFF000000);
  static const hcText = Color(0xFFFFFFFF);
  static const hcAccent = Color(0xFFFFE14D);
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
    accent: AppColors.green,
    accentSoft: AppColors.greenSoft,
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
  static const lg = 20.0;
  static const xl = 28.0;
}
