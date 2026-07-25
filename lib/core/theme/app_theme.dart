import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Pulled directly from assets/logos/logo-long.png: gold shadow/outline,
  // teal wordmark, purple "by Muna" signature accent. Gold leads as
  // primary — warmer and more food/comfort-appropriate for a baby-led
  // weaning app than a bright saturated teal would be; teal becomes the
  // secondary accent instead of the dominant tone.
  static const Color primary = Color(0xFFFFBD59);      // logo gold
  static const Color primaryLight = Color(0xFFFFDBA4);
  static const Color primaryDark = Color(0xFFBF8E43);
  static const Color secondary = Color(0xFF0CC0DF);    // logo teal
  static const Color secondaryLight = Color(0xFF92E3F1);
  static const Color secondaryDark = Color(0xFF08869C);
  static const Color accent = Color(0xFF8454B4);       // logo signature purple
  static const Color background = Color(0xFFFAF7F4);   // off-white warm
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EFE9);
  // primary (gold) is light, so its "on" color needs to be dark to stay
  // readable — a bright saturated color like the old terracotta or the
  // teal secondary could take white, but gold can't.
  static const Color onPrimary = Color(0xFF2D2015);
  static const Color onSecondary = Color(0xFFFFFFFF);
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
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.onBackground),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onBackground),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onBackground),
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
