import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/adaptive/adaptive_scaffold.dart';
import '../../../design_system/adaptive/screen_type.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../player/player_providers.dart';
import '../../player/presentation/player_view.dart';
import '../../playlists/playlist_providers.dart';
import 'channel_list_pane.dart';

const _destinations = [
  AdaptiveDestination(
      icon: Icons.live_tv_outlined, selectedIcon: Icons.live_tv_rounded, label: 'En vivo'),
  AdaptiveDestination(
      icon: Icons.star_outline_rounded, selectedIcon: Icons.star_rounded, label: 'Favoritos'),
  AdaptiveDestination(
      icon: Icons.movie_outlined, selectedIcon: Icons.movie_rounded, label: 'VOD'),
  AdaptiveDestination(
      icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Ajustes'),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) _debugBootstrap();
  }

  /// Solo debug: `IPTV_AUTOLOAD=<ruta .m3u>` carga una lista y `IPTV_PLAY_NAME=<texto>`
  /// reproduce el primer canal que contenga ese texto.
  Future<void> _debugBootstrap() async {
    final path = Platform.environment['IPTV_AUTOLOAD'];
    if (path == null) return;
    await ref.read(playlistProvider.future); // esperar al build() inicial
    await ref.read(playlistProvider.notifier).loadFile(path);
    final name = Platform.environment['IPTV_PLAY_NAME'];
    if (name == null || !mounted) return;
    final channels = ref.read(playlistProvider).valueOrNull?.channels ?? const [];
    final hit = channels.where((c) => c.name.contains(name));
    if (hit.isNotEmpty) await ref.read(playChannelProvider)(hit.first);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: _index,
      onSelected: (i) => setState(() => _index = i),
      body: _index == 0
          ? const _LiveTab()
          : GlassCard(
              child: Center(
                child: Text(_destinations[_index].label,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ), // TODO: features restantes
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
              builder: (_) => const Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(child: PlayerView()),
              ),
            ));
          },
        );
      }

      final listWidth = (c.maxWidth * 0.32).clamp(300.0, 440.0);
      final ultraWide = c.maxWidth >= ScreenType.ultraWideBreakpoint;
      return Row(
        children: [
          SizedBox(
            width: listWidth,
            child: GlassCard(
              child: ChannelListPane(onChannelTap: ref.read(playChannelProvider)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _PlayerColumn()),
          if (ultraWide) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 360,
              child: GlassCard(child: Center(child: Text('Guía EPG (pendiente)'))),
            ),
          ],
        ],
      );
    });
  }

  // Aproximación del ancho ocupado por la navegación lateral (solo para clasificar).
  double _navWidth(BuildContext context) => ScreenType.of(context).isCompact ? 0 : 88;
}

class _PlayerColumn extends ConsumerWidget {
  const _PlayerColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, c) {
      // Reproductor 16:9 limitado por alto; el resto, tarjeta de información.
      final maxPlayerH = math.max(220.0, c.maxHeight - 140);
      final playerH = math.min(c.maxWidth * 9 / 16, maxPlayerH);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: playerH * 16 / 9,
              height: playerH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: PlayerView(),
                ),
              ),
            ),
          ),
          if (c.maxHeight - playerH > 110) ...[
            const SizedBox(height: 12),
            const Expanded(child: _NowPlayingCard()),
          ],
        ],
      );
    });
  }
}

class _NowPlayingCard extends ConsumerWidget {
  const _NowPlayingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ch = ref.watch(currentChannelProvider);
    final s = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: ch == null
          ? Center(
              child: Text('Elige un canal de la lista para empezar',
                  style: TextStyle(color: s.onSurfaceVariant)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AHORA REPRODUCIENDO',
                      style: TextStyle(
                          color: s.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text(ch.name.replaceAll(RegExp(r'\s*\|\s*[A-Z]{2}$'), ''),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (ch.group.isNotEmpty) _Pill(icon: Icons.folder_outlined, text: ch.group),
                      if (ch.number != null) _Pill(icon: Icons.tag_rounded, text: 'Canal ${ch.number}'),
                      if (ch.supportsCatchup)
                        _Pill(
                          icon: Icons.history_rounded,
                          text: ch.catchupDays == null
                              ? 'Catch-up'
                              : 'Catch-up ${ch.catchupDays} d',
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: s.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: s.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}
