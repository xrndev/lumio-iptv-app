import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../../../core/models/media.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
import '../../player/presentation/player_page.dart';
import 'channel_tile.dart';
import '../../playlists/playlist_providers.dart';
import '../../vod/presentation/detail_pages.dart';
import '../../vod/presentation/media_page.dart';
import '../../vod/vod_providers.dart';

/// Búsqueda global: canales, películas y series a la vez.
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).colorScheme;
    final q = ref.watch(globalSearchProvider).trim();
    final results = ref.watch(globalResultsProvider);
    final hasXtream = ref.watch(xtreamCredentialsProvider) != null;
    final loadingCatalogs = hasXtream &&
        (ref.watch(mediaCatalogProvider(MediaKind.movies)).isLoading ||
            ref.watch(mediaCatalogProvider(MediaKind.series)).isLoading);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Text('Buscar',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => ref.read(globalSearchProvider.notifier).state = v,
                    decoration: const InputDecoration(
                      hintText: 'Canales, películas y series',
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loadingCatalogs)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Cargando catálogo de películas y series…', style: TextStyle(fontSize: 12)),
              ]),
            ),
          Expanded(
            child: q.length < 2
                ? Center(child: Text('Escribe al menos 2 letras', style: TextStyle(color: s.onSurfaceVariant)))
                : results.isEmpty && !loadingCatalogs
                    ? Center(child: Text('Sin resultados para "$q"', style: TextStyle(color: s.onSurfaceVariant)))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          if (results.channels.isNotEmpty) ...[
                            _SectionTitle('Canales', results.channels.length),
                            for (final c in results.channels) _ChannelRow(channel: c),
                          ],
                          if (results.movies.isNotEmpty) ...[
                            _SectionTitle('Películas', results.movies.length),
                            _PosterRow(items: results.movies),
                          ],
                          if (results.series.isNotEmpty) ...[
                            _SectionTitle('Series', results.series.length),
                            _PosterRow(items: results.series),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.count);
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text(count >= globalResultLimit ? '$count+' : '$count',
            style: TextStyle(color: s.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: channelTileExtent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ChannelTile(channel: channel, onTap: () => openPlayer(context, ref, channel)),
      ),
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.items});
  final List<MediaEntry> items;

  @override
  Widget build(BuildContext context) {
    return WheelScrollRow(
      height: 270,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final m in items)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              width: 140,
              child: PosterCard(entry: m, onTap: () => openMediaDetail(context, m)),
            ),
          ),
      ],
    );
  }
}
