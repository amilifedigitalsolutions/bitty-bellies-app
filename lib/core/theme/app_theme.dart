import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Blue-violet (from the logo's "by Muna" signature gradient) as primary —
  // gold reads poorly as text/button-label color (weak contrast against
  // light backgrounds), so it's demoted to secondary where it's only ever
  // used as a fill behind dark text, never as text/border color itself.
  // Purple (also from the signature) stays as a minor accent.
  static const Color primary = Color(0xFF546CC0);      // signature blue-violet
  static const Color primaryLight = Color(0xFFB2BDE3);
  static const Color primaryDark = Color(0xFF37467D);
  static const Color secondary = Color(0xFFFFBD59);    // logo gold
  static const Color secondaryLight = Color(0xFFFFDBA4);
  static const Color secondaryDark = Color(0xFFBF8E43);
  static const Color accent = Color(0xFF8454B4);       // signature purple
  static const Color accentLight = Color(0xFFC8B2DD);
  // Sampled directly from the wordmark text in assets/logos/logo-long.png —
  // distinct from `primary` (which comes from a different element of the
  // logo, its small "signature" mark, not the main wordmark itself).
  static const Color logoBlue = Color(0xFF0CC0DF);
  // Warmer and more differentiated than the previous near-white pair —
  // background reads as a genuine warm cream rather than off-white, and
  // surface (cards) sits a step lighter than background so cards read as
  // distinct layers instead of blending into a flat white page.
  static const Color background = Color(0xFFF5EEE1);
  static const Color surface = Color(0xFFFFFBF3);
  static const Color surfaceVariant = Color(0xFFEFE1CC);
  // primary (blue-violet) is dark/saturated enough for white text; secondary
  // (gold) is light, so its "on" color needs to stay dark to be readable.
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF2D2015);
  static const Color onBackground = Color(0xFF2D2015);
  static const Color onSurface = Color(0xFF2D2015);
  static const Color textSecondary = Color(0xFF7A6A5A);
  static const Color border = Color(0xFFE0D5C8);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF388E3C);
  static const Color allergenTag = Color(0xFFFFE0B2);
  static const Color safetyTag = Color(0xFFFFCDD2);
  static const Color chokingTag = Color(0xFFFF8A65);

  // Flat pastel fills for Wonder-Weeks-style color-blocked sections (stat
  // pills, folder headers, hero bands) — cycles through the existing brand
  // tints instead of introducing new hues, so the app still reads as this
  // app's palette rather than a generic pastel kit.
  static const List<Color> pastelFills = [primaryLight, secondaryLight, accentLight];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryLight,
          onSecondaryContainer: AppColors.onBackground,
          tertiary: AppColors.accent,
          onTertiary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceContainerHighest: AppColors.surfaceVariant,
          outline: AppColors.border,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.onBackground),
          titleTextStyle: TextStyle(
            color: AppColors.onBackground,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
          ),
        ),
        // Flat, borderless, generously rounded — pastel color-blocking
        // instead of a bordered white card is the core Wonder-Weeks trait.
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        // Fully-rounded pill buttons (radius = half the button height).
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primaryLight,
          labelStyle: const TextStyle(fontSize: 12, fontFamily: 'Nunito', color: AppColors.onBackground),
          secondaryLabelStyle: const TextStyle(fontSize: 12, fontFamily: 'Nunito', color: AppColors.onBackground),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        // White, not the app's usual cream/tan — sheets and dialogs sit on
        // top of the screen behind them, so a clean white reads as a
        // distinct surface. surfaceTintColor: transparent is required too;
        // Material 3 otherwise washes an elevation-based tint (leaning on
        // colorScheme.primary) over "surface" colored widgets, which is
        // what made these read as tan/cream even with no color set.
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        // Minimal flat bar with a soft pastel pill behind the active icon,
        // no shadow — matches the plain outlined-icon bottom nav look.
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          height: 68,
          indicatorColor: AppColors.primaryLight,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 11,
                fontFamily: 'Nunito',
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                color: states.contains(WidgetState.selected) ? AppColors.onBackground : AppColors.textSecondary,
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected) ? AppColors.primaryDark : AppColors.textSecondary,
              )),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.onBackground),
          displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.onBackground),
          headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.onBackground),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          headlineSmall: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onBackground),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onBackground),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      );
}
