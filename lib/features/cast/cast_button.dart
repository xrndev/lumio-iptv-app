import 'package:cast/cast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/channel.dart';
import '../../platform_channels/tv_provider.dart';
import '../player/player_providers.dart';
import 'cast_controller.dart';

/// Botón "Emitir a Chromecast" para la barra del reproductor. No aparece en TV ni en web.
class CastButton extends ConsumerWidget {
  const CastButton({super.key, required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tv = ref.watch(isTelevisionProvider).valueOrNull ?? false;
    if (tv || kIsWeb) return const SizedBox.shrink();
    final cast = ref.watch(castControllerProvider);
    return IconButton(
      tooltip: cast.casting ? 'Emitiendo en ${cast.device!.name}' : 'Emitir a Chromecast',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      color: cast.casting ? Theme.of(context).colorScheme.primary : Colors.white,
      icon: Icon(cast.casting ? Icons.cast_connected_rounded : Icons.cast_rounded),
      onPressed: () => showDialog<void>(context: context, builder: (_) => CastDialog(channel: channel)),
    );
  }
}

class CastDialog extends ConsumerStatefulWidget {
  const CastDialog({super.key, required this.channel});
  final Channel channel;

  @override
  ConsumerState<CastDialog> createState() => _CastDialogState();
}

class _CastDialogState extends ConsumerState<CastDialog> {
  late final Future<List<CastDevice>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = ref.read(castControllerProvider).casting
        ? Future.value(const <CastDevice>[])
        : ref.read(castControllerProvider.notifier).discover();
  }

  Future<void> _pick(CastDevice d) async {
    final engine = ref.read(playerEngineProvider);
    final pos = engine.player.state.position;
    Navigator.of(context).pop();
    // La cuenta suele permitir una sola conexión: se libera la del móvil antes de emitir.
    final startAt = widget.channel.isLive ? null : pos;
    await engine.stop();
    await ref.read(castControllerProvider.notifier).start(d, widget.channel, startAt: startAt);
  }

  @override
  Widget build(BuildContext context) {
    final cast = ref.watch(castControllerProvider);
    return AlertDialog(
      title: const Text('Emitir a Chromecast'),
      content: SizedBox(
        width: 380,
        child: cast.casting
            ? Text('Emitiendo en ${cast.device!.name}.')
            : FutureBuilder<List<CastDevice>>(
                future: _devices,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Row(children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Buscando dispositivos…'),
                    ]);
                  }
                  final list = snap.data ?? const <CastDevice>[];
                  if (snap.hasError || list.isEmpty) {
                    return const Text(
                        'No se ha encontrado ningún Chromecast. Comprueba que está encendido y en la misma red Wi-Fi.');
                  }
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final d in list)
                      ListTile(
                        leading: const Icon(Icons.cast_rounded),
                        title: Text(d.name),
                        onTap: () => _pick(d),
                      ),
                  ]);
                },
              ),
      ),
      actions: [
        if (cast.casting)
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(castControllerProvider.notifier).stop();
            },
            child: const Text('Dejar de emitir'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
