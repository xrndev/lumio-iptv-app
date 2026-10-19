import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marca de Lumio: una "L" cuyo pie es un triángulo de reproducción.
/// Misma geometría que `assets/branding/lumio_mark.svg` (lienzo de 1024).
class LumioMark extends StatelessWidget {
  const LumioMark({super.key, this.size = 40, this.color});

  final double size;

  /// Si se indica, la marca se pinta plana; si no, con el degradado violeta→cian.
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LumioMarkPainter(color));
}

class _LumioMarkPainter extends CustomPainter {
  const _LumioMarkPainter(this.color);
  final Color? color;

  // Caja de la marca dentro del lienzo de 1024: x 292..790, y 200..824.
  static const _box = Rect.fromLTRB(292, 200, 790, 824);

  @override
  void paint(Canvas canvas, Size size) {
    // Ajustar la caja de la marca al tamaño pedido, centrada.
    final scale = size.shortestSide / _box.height;
    canvas
      ..translate(
        (size.width - _box.width * scale) / 2 - _box.left * scale,
        (size.height - _box.height * scale) / 2 - _box.top * scale,
      )
      ..scale(scale);

    final paint = Paint()..isAntiAlias = true;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = AppColors.accentGradient.createShader(_box);
    }

    // Barra vertical.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(292, 200, 136, 624), const Radius.circular(68)),
      paint,
    );

    // Triángulo de reproducción con esquinas redondeadas (relleno + trazo redondo).
    final tri = Path()
      ..moveTo(488, 660)
      ..lineTo(488, 804)
      ..lineTo(764, 732)
      ..close();
    canvas
      ..drawPath(tri, paint)
      ..drawPath(
        tri,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 40
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_LumioMarkPainter old) => old.color != color;
}
