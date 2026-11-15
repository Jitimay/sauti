import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Minimum interactive size (WCAG 2.5.5 / Material: 48dp; Sauti uses 56).
  static const minTouch = 56.0;

  static ThemeData standard() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE6F5),
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.amberDeep,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFCEBD0),
      onSecondaryContainer: Color(0xFF4A2C00),
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: Color(0xFFEDEFF2),
      outline: AppColors.outline,
      outlineVariant: Color(0xFFE5E7EB),
    );
    return _build(scheme, StatusColors.light, scaffold: AppColors.background, borderWidth: 1);
  }

  static ThemeData highContrast() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.hcAccent,
      onPrimary: Colors.black,
      primaryContainer: Colors.black,
      onPrimaryContainer: AppColors.hcAccent,
      secondary: AppColors.hcAccent,
      onSecondary: Colors.black,
      error: AppColors.hcError,
      onError: Colors.black,
      surface: AppColors.hcSurface,
      onSurface: AppColors.hcText,
      onSurfaceVariant: AppColors.hcText,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Colors.black,
      surfaceContainer: Colors.black,
      outline: AppColors.hcText,
      outlineVariant: AppColors.hcText,
    );
    return _build(scheme, StatusColors.highContrast, scaffold: Colors.black, borderWidth: 2);
  }

  static ThemeData _build(ColorScheme s, StatusColors status, {required Color scaffold, required double borderWidth}) {
    final base = ThemeData(useMaterial3: true, colorScheme: s, visualDensity: VisualDensity.standard);
    // Larger-than-default type scale: readable for elderly / low-vision users.
    final text = base.textTheme
        .copyWith(
          displaySmall: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
          headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
          headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
          titleLarge: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, height: 1.3),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
          bodyLarge: const TextStyle(fontSize: 18, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 16, height: 1.45),
          bodySmall: const TextStyle(fontSize: 14, height: 1.4),
          labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        )
        .apply(bodyColor: s.onSurface, displayColor: s.onSurface);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const minSize = Size(minTouch, minTouch);

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: s.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: s.outlineVariant, width: borderWidth),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minSize, shape: shape, textStyle: text.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
          side: BorderSide(color: s.outline, width: borderWidth),
          foregroundColor: s.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize, textStyle: text.labelLarge),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: minSize)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.outline, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: s.primary, width: borderWidth + 1),
        ),
        labelStyle: text.bodyLarge,
      ),
      listTileTheme: ListTileThemeData(minVerticalPadding: 12, iconColor: s.onSurface, minTileHeight: minTouch),
      switchTheme: SwitchThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: s.surface,
        indicatorColor: s.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      chipTheme: base.chipTheme.copyWith(labelStyle: text.bodyMedium, padding: const EdgeInsets.all(10)),
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: borderWidth),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
