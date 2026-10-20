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
                Icon(Icons.translate_rounded, size: 16, color: selected ? s.primary : s.onSurfaceVariant),
                const SizedBox(width: 4),
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
