import 'package:cast/cast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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
      tooltip: cast.casting ? AppLocalizations.of(context).castTooltipActive(cast.device!.name) : AppLocalizations.of(context).castTooltip,
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
      title: Text(AppLocalizations.of(context).castTooltip),
      content: SizedBox(
        width: 380,
        child: cast.casting
            ? Text(AppLocalizations.of(context).castActive(cast.device!.name))
            : FutureBuilder<List<CastDevice>>(
                future: _devices,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return Row(children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context).castSearching),
                    ]);
                  }
                  final list = snap.data ?? const <CastDevice>[];
                  if (snap.hasError || list.isEmpty) {
                    return Text(AppLocalizations.of(context).castNone);
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
            child: Text(AppLocalizations.of(context).castStop),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context).commonClose)),
      ],
    );
  }
}
