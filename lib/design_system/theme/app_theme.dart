import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF4F7CFF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Premium: negro puro para pantallas OLED.
  static ThemeData oled() => _build(Brightness.dark, oled: true);

  static ThemeData _build(Brightness b, {bool oled = false}) {
    var scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
    if (oled) scheme = scheme.copyWith(surface: Colors.black);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: oled ? Colors.black : null,
      visualDensity: VisualDensity.standard,
      // Foco visible para teclado / D-Pad.
      focusColor: scheme.primary.withAlpha(60),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withAlpha(235), // glass sutil
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
