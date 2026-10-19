import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../design_system/theme/app_theme.dart';
import '../player_providers.dart';
import 'player_overlay.dart';

/// Superficie de vídeo. Los controles se pasan como `controls` de [Video] para
/// que también existan en pantalla completa.
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
            child: Video(
              controller: engine.video,
              controls: (state) => PlayerOverlay(state: state),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
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
            ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: const Icon(Icons.live_tv_rounded, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('Selecciona un canal',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
