import 'package:flutter/material.dart';

/// Tokens de marca (independientes del modo claro/oscuro).
class AppColors {
  const AppColors._();

  static const violet = Color(0xFF8B6CFF);
  static const cyan = Color(0xFF22D3EE);
  static const live = Color(0xFFFF4D6D);

  static const accentGradient = LinearGradient(
    colors: [violet, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(seedColor: AppColors.violet, brightness: Brightness.dark).copyWith(
          primary: AppColors.violet,
          secondary: AppColors.cyan,
          surface: const Color(0xFF0B0D14),
          surfaceContainer: const Color(0xFF141824),
          surfaceContainerHigh: const Color(0xFF1B2030),
          onSurface: const Color(0xFFE8EAF2),
          onSurfaceVariant: const Color(0xFF9AA1B5),
          outlineVariant: const Color(0xFF2A3045),
        ),
      );

  static ThemeData light() => _build(
        ColorScheme.fromSeed(seedColor: AppColors.violet, brightness: Brightness.light).copyWith(
          primary: const Color(0xFF6C4BEB),
          secondary: const Color(0xFF0891B2),
          surface: const Color(0xFFF4F5FA),
          surfaceContainer: Colors.white,
          surfaceContainerHigh: const Color(0xFFEBEDF5),
          outlineVariant: const Color(0xFFD8DCEA),
        ),
      );

  /// Premium: negro puro para pantallas OLED.
  static ThemeData oled() => dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: dark().colorScheme.copyWith(surface: Colors.black),
      );

  static ThemeData _build(ColorScheme s) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      scaffoldBackgroundColor: s.surface,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Roboto', 'Inter', 'SF Pro Text', 'Noto Sans'],
      // Foco visible para teclado / D-Pad.
      focusColor: s.secondary.withValues(alpha: 0.25),
      splashFactory: InkSparkle.splashFactory,
      textTheme: ThemeData(brightness: s.brightness).textTheme.apply(
            bodyColor: s.onSurface,
            displayColor: s.onSurface,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: s.outlineVariant,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(s.onSurfaceVariant.withValues(alpha: 0.35)),
      ),
    );
  }
}
