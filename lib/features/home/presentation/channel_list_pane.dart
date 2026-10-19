import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../../../core/network/xtream_client.dart';
import '../../../core/util/channel_names.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
import '../../player/player_providers.dart';
import 'channel_tile.dart';
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
        action: 'Reintentar',
        onAction: () => ref.invalidate(playlistProvider),
        secondaryAction: 'Probar otra fuente',
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

    return WheelScrollRow(
      children: [
        CategoryChip(
            label: 'Todos',
            selected: selected == null,
            onTap: () => ref.read(selectedGroupProvider.notifier).state = null),
        for (final g in groups)
          CategoryChip(
              label: prettyGroupName(g),
              selected: selected == g,
              onTap: () => ref.read(selectedGroupProvider.notifier).state = g),
      ],
    );
  }
}

class _AccountBanner extends ConsumerWidget {
  const _AccountBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(xtreamAccountProvider);
    if (a == null) return const SizedBox.shrink();
    final notice = accountNotice(a, DateTime.now());
    if (notice == null) return const SizedBox.shrink();
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: s.onErrorContainer, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(notice, style: TextStyle(color: s.onErrorContainer, fontSize: 13))),
          ]),
        ),
      ),
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
      itemExtent: channelTileExtent,
      itemBuilder: (context, i) {
        final c = channels[i];
        return ChannelTile(
          channel: c,
          playing: currentIndex == c.index,
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    this.onAction,
    this.secondaryAction,
  });
  final IconData icon;
  final String text;
  final String action;

  /// Acción principal; por defecto abre el diálogo de añadir fuente.
  final VoidCallback? onAction;
  final String? secondaryAction;

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
            FilledButton(
              onPressed: onAction ?? () => showAddSourceDialog(context),
              child: Text(action),
            ),
            if (secondaryAction != null)
              TextButton(
                onPressed: () => showAddSourceDialog(context),
                child: Text(secondaryAction!),
              ),
          ],
        ),
      ),
    );
  }
}
