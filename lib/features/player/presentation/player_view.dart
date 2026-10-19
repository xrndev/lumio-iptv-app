import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../data/player_engine.dart';
import '../player_providers.dart';

/// Superficie de vídeo con controles mínimos accesibles.
class PlayerView extends ConsumerWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(playerEngineProvider);
    final channel = ref.watch(currentChannelProvider);

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: channel == null ? 'Reproductor sin canal' : 'Reproduciendo ${channel.name}',
            child: Video(controller: engine.video, controls: null),
          ),
          if (channel == null)
            const Center(
              child: Text('Selecciona un canal', style: TextStyle(color: Colors.white70)),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: _Controls(engine: engine, title: channel?.name ?? ''),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.engine, required this.title});

  final PlayerEngine engine;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            StreamBuilder<bool>(
              stream: engine.player.stream.playing,
              initialData: engine.player.state.playing,
              builder: (context, snap) {
                final playing = snap.data ?? false;
                return IconButton(
                  // 48dp mínimo de zona táctil.
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: playing ? 'Pausar' : 'Reproducir',
                  color: Colors.white,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: engine.togglePlay,
                );
              },
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            PopupMenuButton<AspectMode>(
              tooltip: 'Relación de aspecto',
              icon: const Icon(Icons.aspect_ratio, color: Colors.white),
              onSelected: engine.setAspect,
              itemBuilder: (_) => [
                for (final m in AspectMode.values) PopupMenuItem(value: m, child: Text(m.label)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
