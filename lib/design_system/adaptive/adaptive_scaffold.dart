import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/focus_ring.dart';
import '../widgets/glass_card.dart';
import '../widgets/lumio_mark.dart';
import 'screen_type.dart';

class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Navegación según [ScreenType]:
/// compact → barra inferior flotante · medium → sidebar de iconos ·
/// expanded → sidebar con etiquetas, colapsable.
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.sidebarFooter,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  /// Extra al pie del sidebar (p. ej. selector de idioma); recibe si el menú está expandido.
  final Widget Function(BuildContext context, bool extended)? sidebarFooter;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _sidebarExtended = true;

  @override
  Widget build(BuildContext context) {
    final type = ScreenType.of(context);

    if (type.isCompact) {
      return Scaffold(
        extendBody: true,
        body: AppBackground(child: SafeArea(bottom: false, child: widget.body)),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GlassCard(
              radius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  for (var i = 0; i < widget.destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        dest: widget.destinations[i],
                        selected: i == widget.selectedIndex,
                        extended: false,
                        stacked: true,
                        onTap: () => widget.onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final extended = type.isExpanded && _sidebarExtended;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FocusTraversalGroup(
                  child: SizedBox(
                    width: extended ? 208 : 76,
                    child: GlassCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Brand(extended: extended),
                          const SizedBox(height: 16),
                          for (var i = 0; i < widget.destinations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _NavItem(
                                dest: widget.destinations[i],
                                selected: i == widget.selectedIndex,
                                extended: extended,
                                onTap: () => widget.onSelected(i),
                              ),
                            ),
                          const Spacer(),
                          if (widget.sidebarFooter != null) widget.sidebarFooter!(context, extended),
                          if (type.isExpanded)
                            IconButton(
                              tooltip: _sidebarExtended ? AppLocalizations.of(context).menuCollapse : AppLocalizations.of(context).menuExpand,
                              icon: Icon(_sidebarExtended
                                  ? Icons.keyboard_double_arrow_left_rounded
                                  : Icons.keyboard_double_arrow_right_rounded),
                              onPressed: () => setState(() => _sidebarExtended = !_sidebarExtended),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        const SizedBox(width: 2),
        Semantics(
          label: 'Lumio',
          child: const SizedBox(width: 40, height: 40, child: LumioMark(size: 40)),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text('Lumio',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
        ],
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.dest,
    required this.selected,
    required this.extended,
    required this.onTap,
    this.stacked = false,
  });

  final AdaptiveDestination dest;
  final bool selected;
  final bool extended;
  final bool stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final color = selected ? s.primary : s.onSurfaceVariant;
    final icon = Icon(selected ? dest.selectedIcon : dest.icon, color: color, size: 24);
    final label = Text(
      dest.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: selected ? s.onSurface : s.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: stacked ? 10 : 14,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: dest.label,
      child: Tooltip(
        message: extended || stacked ? '' : dest.label,
        child: FocusRing(
          radius: 16,
          child: InkWell(
          autofocus: selected,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80), // ágil también en mandos de TV con CPU modesta
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(horizontal: extended ? 14 : (stacked ? 0 : 8), vertical: stacked ? 8 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected ? s.primary.withValues(alpha: 0.16) : Colors.transparent,
              border: Border.all(
                color: selected ? s.primary.withValues(alpha: 0.45) : Colors.transparent,
              ),
            ),
            child: stacked
                ? Column(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(height: 2), label])
                : Row(
                    mainAxisAlignment:
                        extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      icon,
                      if (extended) ...[const SizedBox(width: 14), Flexible(child: label)],
                    ],
                  ),
          ),
        ),
        ),
      ),
    );
  }
}
