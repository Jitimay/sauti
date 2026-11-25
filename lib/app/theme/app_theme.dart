import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Minimum interactive size (WCAG 2.5.5 / Material: 48dp; Sauti uses 56).
  static const minTouch = 56.0;

  /// Atkinson Hyperlegible Next: drawn by the Braille Institute so that
  /// similar letters (Il1, O0, rn/m) stay distinct for low-vision readers.
  static const fontFamily = 'Atkinson';

  static ThemeData standard() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blueSoft,
      onPrimaryContainer: AppColors.blueDeep,
      secondary: AppColors.green,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.greenSoft,
      tertiary: Color(0xFF0F766E),
      tertiaryContainer: Color(0xFFD9F2ED),
      onTertiaryContainer: Color(0xFF124F48),
      onSecondaryContainer: AppColors.greenDeep,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.sunken,
      surfaceContainerHigh: AppColors.sunken,
      outline: AppColors.outline,
      outlineVariant: AppColors.line,
      surfaceTint: Colors.transparent,
    );
    return _build(scheme, StatusColors.light, scaffold: AppColors.canvas, borderWidth: 1);
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
      surfaceContainerHigh: Colors.black,
      outline: AppColors.hcText,
      outlineVariant: AppColors.hcText,
      surfaceTint: Colors.transparent,
    );
    return _build(scheme, StatusColors.highContrast, scaffold: Colors.black, borderWidth: 2);
  }

  static ThemeData _build(ColorScheme s, StatusColors status, {required Color scaffold, required double borderWidth}) {
    final base = ThemeData(useMaterial3: true, colorScheme: s, visualDensity: VisualDensity.standard, fontFamily: fontFamily);
    // Larger-than-default type scale: readable for elderly / low-vision users.
    // Figures are tabular everywhere so amounts line up in lists.
    const tnum = [FontFeature.tabularFigures()];
    final text = base.textTheme
        .copyWith(
          displayMedium: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.05, fontFeatures: tnum),
          displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.1, fontFeatures: tnum),
          headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15),
          headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2, fontFeatures: tnum),
          headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25, fontFeatures: tnum),
          titleLarge: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3),
          titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, fontFeatures: tnum),
          titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
          bodyLarge: const TextStyle(fontSize: 18, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 16, height: 1.45),
          bodySmall: const TextStyle(fontSize: 14.5, height: 1.4),
          labelLarge: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.1),
          labelMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          labelSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        )
        .apply(bodyColor: s.onSurface, displayColor: s.onSurface, fontFamily: fontFamily);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
    const minSize = Size(minTouch, minTouch);
    final hc = status.isHighContrast;

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      // Cards: white on the warm canvas with a hairline, no drop shadow.
      cardTheme: CardThemeData(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: s.outlineVariant, width: borderWidth),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
          elevation: 0,
          disabledBackgroundColor: hc ? Colors.black : AppColors.sunken,
          disabledForegroundColor: hc ? AppColors.hcText : AppColors.muted,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
          backgroundColor: hc ? Colors.black : s.surface,
          side: BorderSide(color: s.outline, width: borderWidth),
          foregroundColor: s.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          textStyle: text.labelLarge,
          foregroundColor: hc ? s.primary : AppColors.navyLight,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: minSize)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: text.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: hc ? s.outline : AppColors.line, width: hc ? borderWidth : 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: s.primary, width: borderWidth + 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: s.error, width: borderWidth + 0.5),
        ),
        prefixIconColor: s.onSurfaceVariant,
        labelStyle: text.bodyLarge?.copyWith(color: s.onSurfaceVariant),
        floatingLabelStyle: text.bodyLarge?.copyWith(color: s.primary, fontWeight: FontWeight.w600),
        hintStyle: text.bodyLarge?.copyWith(color: s.onSurfaceVariant),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 14,
        iconColor: s.onSurface,
        minTileHeight: minTouch + 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.transparent : s.outline),
        thumbColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? (hc ? Colors.black : Colors.white) : (hc ? AppColors.hcText : s.outline)),
        trackColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? s.primary : (hc ? Colors.black : AppColors.sunken)),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.primary : s.outline)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: hc ? s.outline : AppColors.line, width: hc ? borderWidth : 1.5)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md))),
          backgroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected) ? (hc ? s.primary : AppColors.navy) : s.surface),
          foregroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected) ? s.onPrimary : s.onSurface),
          iconColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.onPrimary : s.onSurface),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: hc ? s.primary : AppColors.navyTint,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(
              size: 26,
              color: st.contains(WidgetState.selected) ? (hc ? Colors.black : AppColors.navy) : s.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((st) => text.labelMedium?.copyWith(
              fontWeight: st.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: st.contains(WidgetState.selected) ? s.onSurface : s.onSurfaceVariant,
            )),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: text.bodyMedium,
        padding: const EdgeInsets.all(10),
        side: BorderSide(color: s.outlineVariant, width: borderWidth),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: borderWidth, space: borderWidth),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: hc ? Colors.black : AppColors.sunken,
        borderRadius: BorderRadius.circular(99),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        backgroundColor: hc ? Colors.black : AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: hc ? s.primary : AppColors.error, textColor: hc ? Colors.black : Colors.white),
    );
  }
}
