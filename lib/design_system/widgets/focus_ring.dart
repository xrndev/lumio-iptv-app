import 'package:flutter/material.dart';

/// Aro de foco visible para mando/teclado (D-Pad). Envuelve un widget enfocable
/// (InkWell, botón…) y pinta un borde cuando él o un descendiente tiene el foco.
/// No es enfocable por sí mismo: no altera el orden de navegación.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child, this.radius = 18});

  final Widget child;
  final double radius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: _focused ? color : Colors.transparent,
            width: 3,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
