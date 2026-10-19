import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../../player/player_providers.dart';
import '../../playlists/playlist_providers.dart';
import '../../playlists/presentation/add_source_dialog.dart';

class ChannelListPane extends ConsumerWidget {
  const ChannelListPane({super.key, required this.onChannelTap});

  final void Function(Channel) onChannelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);

    return playlist.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        icon: Icons.error_outline,
        text: 'No se pudo cargar la fuente:\n${_clean(e)}',
        action: 'Probar otra fuente',
      ),
      data: (data) {
        if (data == null) {
          return const _Message(
            icon: Icons.playlist_add,
            text: 'Añade una lista M3U, un archivo o una cuenta Xtream Codes.',
            action: 'Añadir fuente',
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      hintText: 'Buscar canal',
                      leading: const Icon(Icons.search),
                      onChanged: (v) => ref.read(channelSearchProvider.notifier).state = v,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Añadir fuente',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.add),
                    onPressed: () => showAddSourceDialog(context),
                  ),
                ],
              ),
            ),
            const _AccountBanner(),
            Expanded(child: _ChannelList(onTap: onChannelTap)),
          ],
        );
      },
    );
  }

  static String _clean(Object e) =>
      e.toString().replaceFirst(RegExp(r'^(Bad state|Exception|FormatException): '), '');
}

class _AccountBanner extends ConsumerWidget {
  const _AccountBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(xtreamAccountProvider);
    if (a == null) return const SizedBox.shrink();
    final exp = a.expiry == null
        ? 'sin caducidad'
        : 'caduca ${a.expiry!.day.toString().padLeft(2, '0')}/'
            '${a.expiry!.month.toString().padLeft(2, '0')}/${a.expiry!.year}';
    final conns = a.maxConnections == null ? '' : ' · ${a.maxConnections} conexiones';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text('Xtream: ${a.status}, $exp$conns',
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.onTap});
  final void Function(Channel) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(visibleChannelsProvider);
    final current = ref.watch(currentChannelProvider);

    // itemExtent fijo: layout O(1) con 50k filas.
    return ListView.builder(
      itemCount: channels.length,
      itemExtent: 64,
      itemBuilder: (context, i) {
        final c = channels[i];
        return ListTile(
          selected: current?.index == c.index,
          leading: SizedBox(
            width: 48,
            height: 48,
            child: c.logo.isEmpty
                ? const Icon(Icons.tv)
                : Image.network(
                    c.logo,
                    fit: BoxFit.contain,
                    cacheWidth: 96,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const Icon(Icons.tv),
                  ),
          ),
          title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: c.group.isEmpty
              ? null
              : Text(c.group, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => showAddSourceDialog(context), child: Text(action)),
          ],
        ),
      ),
    );
  }
}
