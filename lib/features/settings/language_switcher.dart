import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/widgets/focus_ring.dart';
import '../../l10n/app_localizations.dart';
import 'locale_providers.dart';

/// Nombre de cada idioma en su propio idioma (no se traduce).
const languageNames = {'es': 'Español', 'en': 'English'};

/// Selector de idioma del menú. Expandido: segmentos `ES | EN`; contraído: un botón
/// con el código actual que alterna al siguiente idioma.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = (ref.watch(localeProvider).valueOrNull ?? systemLocale()).languageCode;
    final l = AppLocalizations.of(context);
    final set = ref.read(localeProvider.notifier).set;

    if (!extended) {
      final next = supportedLanguageCodes[(supportedLanguageCodes.indexOf(current) + 1) % supportedLanguageCodes.length];
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _Segment(
          code: current,
          selected: true,
          tooltip: '${l.languageTooltip}: ${languageNames[next]}',
          onTap: () => set(next),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        for (final code in supportedLanguageCodes)
          Expanded(
            child: _Segment(
              code: code,
              selected: code == current,
              tooltip: '${l.languageTooltip}: ${languageNames[code]}',
              onTap: () => set(code),
            ),
          ),
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.code, required this.selected, required this.tooltip, required this.onTap});

  final String code;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: FocusRing(
          radius: 14,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? s.primary.withValues(alpha: 0.16) : Colors.transparent,
                border: Border.all(color: selected ? s.primary.withValues(alpha: 0.45) : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _Flag(code: code, dimmed: !selected),
                const SizedBox(width: 6),
                Text(code.toUpperCase(),
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? s.onSurface : s.onSurfaceVariant,
                    )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandera del idioma, dibujada (los emojis de bandera no salen en Windows ni en todas las TV).
/// `es` → España, `en` → Reino Unido.
class _Flag extends StatelessWidget {
  const _Flag({required this.code, required this.dimmed});

  final String code;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final painter = switch (code) {
      'es' => const _SpainPainter(),
      'en' => const _UkPainter(),
      _ => null,
    };
    if (painter == null) return const Icon(Icons.translate_rounded, size: 16);
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Container(
        width: 24,
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

class _SpainPainter extends CustomPainter {
  const _SpainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFAA151B);
    final yellow = Paint()..color = const Color(0xFFF1BF00);
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * 0.25), red);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.25, size.width, h * 0.5), yellow);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, size.width, h * 0.25), red);
  }

  @override
  bool shouldRepaint(_SpainPainter old) => false;
}

class _UkPainter extends CustomPainter {
  const _UkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    const white = Colors.white, red = Color(0xFFC8102E);

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF012169));
    // Aspas (diagonales): blanca ancha y roja fina encima.
    for (final width in [h * 0.22, h * 0.09]) {
      final p = stroke(width == h * 0.22 ? white : red, width);
      canvas.drawLine(Offset.zero, Offset(w, h), p);
      canvas.drawLine(Offset(w, 0), Offset(0, h), p);
    }
    // Cruz: blanca ancha y roja fina encima.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5 - h * 0.17, w, h * 0.34), Paint()..color = white);
    canvas.drawRect(Rect.fromLTWH(w * 0.5 - h * 0.17, 0, h * 0.34, h), Paint()..color = white);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5 - h * 0.1, w, h * 0.2), Paint()..color = red);
    canvas.drawRect(Rect.fromLTWH(w * 0.5 - h * 0.1, 0, h * 0.2, h), Paint()..color = red);
  }

  @override
  bool shouldRepaint(_UkPainter old) => false;
}
