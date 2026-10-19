import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Fila horizontal desplazable también con la rueda del ratón y arrastrando con
/// el ratón (Flutter solo lo permite por defecto con táctil/teclado).
class WheelScrollRow extends StatefulWidget {
  const WheelScrollRow({
    super.key,
    required this.children,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<WheelScrollRow> createState() => _WheelScrollRowState();
}

class _WheelScrollRowState extends State<WheelScrollRow> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final s = e as PointerScrollEvent;
      if (!_controller.hasClients) return;
      final delta = s.scrollDelta.dy != 0 ? s.scrollDelta.dy : s.scrollDelta.dx;
      final target = (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
      _controller.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onSignal,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
          scrollbars: false,
        ),
        child: SizedBox(
          height: widget.height,
          child: ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}

/// Chip de categoría con el estilo de la app.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : s.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: s.primary,
        backgroundColor: s.surfaceContainerHigh,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
