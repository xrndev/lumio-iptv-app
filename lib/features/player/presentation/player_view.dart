import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../design_system/widgets/lumio_mark.dart';
import '../player_providers.dart';
import 'player_overlay.dart';

/// Superficie de vídeo. Los controles se pasan como `controls` de [Video] para
/// que también existan en pantalla completa.
class PlayerView extends ConsumerWidget {
  const PlayerView({super.key, this.onBack});

  /// Si se indica, la barra superior muestra un botón "volver".
  final VoidCallback? onBack;

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
            child: Video(
              controller: engine.video,
              controls: (state) => PlayerOverlay(state: state, onBack: onBack),
            ),
          ),
          if (channel == null) const IgnorePointer(child: _EmptyPlayer()),
        ],
      ),
    );
  }
}

class _EmptyPlayer extends StatelessWidget {
  const _EmptyPlayer();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF12151F), Color(0xFF0A0C12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LumioMark(size: 72),
            SizedBox(height: 12),
            Text('Selecciona un canal', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
