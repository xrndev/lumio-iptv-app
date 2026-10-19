import 'package:flutter/material.dart';

import 'screen_type.dart';

class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Navegación según [ScreenType]:
/// compact → barra inferior · medium → rail · expanded → sidebar colapsable.
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _sidebarExtended = true;

  @override
  Widget build(BuildContext context) {
    final type = ScreenType.of(context);
    final d = widget.destinations;

    switch (type) {
      case ScreenType.compact:
        return Scaffold(
          body: SafeArea(child: widget.body),
          bottomNavigationBar: NavigationBar(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onSelected,
            destinations: [
              for (final x in d)
                NavigationDestination(
                  icon: Icon(x.icon),
                  selectedIcon: Icon(x.selectedIcon),
                  label: x.label,
                ),
            ],
          ),
        );

      case ScreenType.medium:
      case ScreenType.expanded:
        final extended = type.isExpanded && _sidebarExtended;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                FocusTraversalGroup(
                  child: NavigationRail(
                    extended: extended,
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onSelected,
                    labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                    leading: type.isExpanded
                        ? IconButton(
                            tooltip: _sidebarExtended ? 'Contraer menú' : 'Expandir menú',
                            icon: Icon(_sidebarExtended ? Icons.menu_open : Icons.menu),
                            onPressed: () => setState(() => _sidebarExtended = !_sidebarExtended),
                          )
                        : null,
                    destinations: [
                      for (final x in d)
                        NavigationRailDestination(
                          icon: Icon(x.icon),
                          selectedIcon: Icon(x.selectedIcon),
                          label: Text(x.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: widget.body),
              ],
            ),
          ),
        );
    }
  }
}
