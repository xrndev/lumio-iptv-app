import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/adaptive/adaptive_scaffold.dart';
import '../../../design_system/adaptive/screen_type.dart';
import '../../player/player_providers.dart';
import '../../player/presentation/player_view.dart';
import 'channel_list_pane.dart';

const _destinations = [
  AdaptiveDestination(icon: Icons.live_tv_outlined, selectedIcon: Icons.live_tv, label: 'En vivo'),
  AdaptiveDestination(icon: Icons.star_outline, selectedIcon: Icons.star, label: 'Favoritos'),
  AdaptiveDestination(icon: Icons.movie_outlined, selectedIcon: Icons.movie, label: 'VOD'),
  AdaptiveDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Ajustes'),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _index,
      onSelected: (i) => setState(() => _index = i),
      body: _index == 0
          ? const _LiveTab()
          : Center(child: Text(_destinations[_index].label)), // TODO: features restantes
    );
  }
}

/// compact: solo lista (el reproductor abre a pantalla completa).
/// medium/expanded: lista + reproductor sin interrumpir el stream.
class _LiveTab extends ConsumerWidget {
  const _LiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LayoutBuilder: decide por el espacio disponible tras la navegación.
    return LayoutBuilder(builder: (context, c) {
      final type = ScreenType.fromWidth(c.maxWidth + _navWidth(context));

      if (type.isCompact) {
        return ChannelListPane(
          onChannelTap: (channel) async {
            await ref.read(playChannelProvider)(channel);
            if (!context.mounted) return;
            await Navigator.of(context).push(MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => const Scaffold(body: SafeArea(child: PlayerView())),
            ));
          },
        );
      }

      final listWidth = (c.maxWidth * 0.32).clamp(280.0, 420.0);
      final ultraWide = c.maxWidth >= ScreenType.ultraWideBreakpoint;
      return Row(
        children: [
          SizedBox(
            width: listWidth,
            child: ChannelListPane(onChannelTap: ref.read(playChannelProvider)),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 2200),
                child: const AspectRatio(aspectRatio: 16 / 9, child: PlayerView()),
              ),
            ),
          ),
          if (ultraWide) const SizedBox(width: 360, child: _EpgPlaceholder()),
        ],
      );
    });
  }

  // Aproximación del ancho ocupado por la navegación lateral (solo para clasificar).
  double _navWidth(BuildContext context) =>
      ScreenType.of(context).isCompact ? 0 : 80;
}

class _EpgPlaceholder extends StatelessWidget {
  const _EpgPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Guía EPG (pendiente)'));
}
