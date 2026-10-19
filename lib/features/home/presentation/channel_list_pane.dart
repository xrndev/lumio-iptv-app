import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../../../design_system/theme/app_theme.dart';
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
        icon: Icons.error_outline_rounded,
        text: 'No se pudo cargar la fuente:\n${_clean(e)}',
        action: 'Probar otra fuente',
      ),
      data: (data) {
        if (data == null) {
          return const _Message(
            icon: Icons.playlist_add_rounded,
            text: 'Añade una lista M3U, un archivo o una cuenta Xtream Codes.',
            action: 'Añadir fuente',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(total: data.channels.length),
            const _SearchField(),
            const _GroupChips(),
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

class _Header extends ConsumerWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(visibleChannelsProvider).length;
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          Text('En vivo',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: s.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(shown == total ? '$total' : '$shown / $total',
                style: TextStyle(color: s.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: 'Añadir fuente',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAddSourceDialog(context),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        onChanged: (v) => ref.read(channelSearchProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Buscar canal',
          prefixIcon: Icon(Icons.search_rounded),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

class _GroupChips extends ConsumerWidget {
  const _GroupChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    if (groups.length < 2) return const SizedBox.shrink();
    final selected = ref.watch(selectedGroupProvider);
    final s = Theme.of(context).colorScheme;

    Widget chip(String label, bool isSelected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onTap(),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : s.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: s.primary,
            backgroundColor: s.surfaceContainerHigh,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('Todos', selected == null,
              () => ref.read(selectedGroupProvider.notifier).state = null),
          for (final g in groups)
            chip(g, selected == g, () => ref.read(selectedGroupProvider.notifier).state = g),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
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
    final currentIndex = ref.watch(currentChannelProvider.select((c) => c?.index));
    final s = Theme.of(context).colorScheme;

    if (channels.isEmpty) {
      return Center(
        child: Text('Sin resultados', style: TextStyle(color: s.onSurfaceVariant)),
      );
    }

    // itemExtent fijo: layout O(1) con 50k filas.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      itemCount: channels.length,
      itemExtent: 72,
      itemBuilder: (context, i) {
        final c = channels[i];
        return _ChannelTile(
          channel: c,
          playing: currentIndex == c.index,
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel, required this.playing, required this.onTap});

  final Channel channel;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final name = channel.name.replaceAll(RegExp(r'\s*\|\s*[A-Z]{2}$'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Material(
        color: playing ? s.primary.withValues(alpha: 0.14) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: playing ? s.primary.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          hoverColor: s.onSurface.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: s.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: channel.logo.isEmpty
                      ? Icon(Icons.tv_rounded, color: s.onSurfaceVariant)
                      : Image.network(
                          channel.logo,
                          fit: BoxFit.contain,
                          cacheWidth: 96,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.tv_rounded, color: s.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: playing ? FontWeight.w700 : FontWeight.w600)),
                      if (channel.group.isNotEmpty)
                        Text(channel.group,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                if (playing)
                  const Icon(Icons.graphic_eq_rounded, color: AppColors.cyan)
                else if (channel.supportsCatchup)
                  Icon(Icons.history_rounded, size: 18, color: s.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
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
            ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: Icon(icon, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => showAddSourceDialog(context), child: Text(action)),
          ],
        ),
      ),
    );
  }
}
