import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../player_providers.dart';
import 'player_view.dart';

/// Reproduce [channel] a pantalla completa y detiene el stream al salir.
Future<void> openPlayer(BuildContext context, WidgetRef ref, Channel channel,
    {Duration? startAt}) async {
  await ref.read(playChannelProvider)(channel, startAt: startAt);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => const PlayerPage(),
  ));
}

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(playerEngineProvider).stop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: PlayerView(onBack: () => Navigator.of(context).maybePop()),
        ),
      ),
    );
  }
}
