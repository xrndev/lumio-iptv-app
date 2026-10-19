import 'package:flutter/widgets.dart';

/// Clases de ventana Material 3: compact < 600dp, medium 600–839dp, expanded ≥ 840dp.
enum ScreenType {
  compact,
  medium,
  expanded;

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;

  /// Ancho a partir del cual se añade un tercer panel (ultra-wide).
  static const double ultraWideBreakpoint = 1600;

  static ScreenType fromWidth(double width) {
    if (width >= expandedBreakpoint) return ScreenType.expanded;
    if (width >= mediumBreakpoint) return ScreenType.medium;
    return ScreenType.compact;
  }

  /// Usa el ancho de la ventana (no del padre). Para layouts locales usar
  /// [fromWidth] con el `maxWidth` de un `LayoutBuilder`.
  static ScreenType of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;
  bool get isExpanded => this == expanded;
}
