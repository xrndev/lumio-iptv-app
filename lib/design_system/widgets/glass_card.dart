import 'dart:ui';

import 'package:flutter/material.dart';

/// Permite desactivar el desenfoque de [GlassCard] en todo el árbol (TV: la GPU de un
/// Fire Stick no aguanta re-desenfocar pantallas enteras al cambiar de pestaña).
class GlassBlur extends InheritedWidget {
  const GlassBlur({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassBlur>()?.enabled ?? true;

  @override
  bool updateShouldNotify(GlassBlur old) => enabled != old.enabled;
}

/// Panel con desenfoque (glassmorphism sutil). No usar dentro de listas largas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.blur = 20,
    this.opacity = 0.6,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: s.surfaceContainer.withValues(alpha: opacity),
        borderRadius: r,
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.6)),
      ),
      // Material transparente: los InkWell/ListTile de dentro pintan su efecto
      // sobre él y no quedan ocultos tras el fondo del DecoratedBox.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
    if (blur <= 0 || !GlassBlur.of(context)) return ClipRRect(borderRadius: r, child: panel);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: panel),
    );
  }
}

/// Fondo de la app: degradado suave con dos "manchas" de color de marca.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -1.0),
          radius: 1.2,
          colors: [s.primary.withValues(alpha: 0.18), Colors.transparent],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, 1.0),
            radius: 1.0,
            colors: [s.secondary.withValues(alpha: 0.12), Colors.transparent],
          ),
        ),
        child: child,
      ),
    );
  }
}
