import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/library/library_data.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/media.dart';
import '../../../core/network/xtream_client.dart';
import '../../../design_system/widgets/cached_logo.dart';
import '../../../design_system/widgets/focus_ring.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
import '../../library/library_providers.dart';
import '../../library/presentation/library_sync_dialog.dart';
import '../../player/presentation/player_page.dart';
import '../../playlists/playlist_providers.dart';
import '../../vod/presentation/detail_pages.dart';
import '../../vod/presentation/media_page.dart';
import '../../vod/vod_providers.dart';
import 'channel_tile.dart';

/// "Favoritos": continuar viendo, canales recientes y favoritos por tipo.
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  LibraryKind _kind = LibraryKind.channel;

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(currentLibraryProvider);
    final channels = ref.watch(channelsByUidProvider);
    final cont = lib.continueWatching();

    return GlassCard(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(onSync: () => showLibrarySyncDialog(context))),
          if (cont.isNotEmpty) ...[
            SliverToBoxAdapter(child: _SectionTitle(AppLocalizations.of(context).continueWatching)),
            SliverToBoxAdapter(
              child: WheelScrollRow(
                height: 292,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [for (final e in cont) _ContinueCard(entry: e)],
              ),
            ),
          ],
          SliverToBoxAdapter(child: _SectionTitle(AppLocalizations.of(context).myFavorites)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SegmentedButton<LibraryKind>(
                showSelectedIcon: false,
                segments: [
                  for (final k in LibraryKind.values)
                    ButtonSegment(
                      value: k,
                      icon: Icon(_icon(k)),
                      label: Text('${_label(AppLocalizations.of(context), k)} (${lib.favoriteUids(k).length})'),
                    ),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
            ),
          ),
          ..._content(lib, channels),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static IconData _icon(LibraryKind k) => switch (k) {
        LibraryKind.channel => Icons.live_tv_rounded,
        LibraryKind.movie => Icons.movie_rounded,
        LibraryKind.series => Icons.video_library_rounded,
      };

  static String _label(AppLocalizations l, LibraryKind k) => switch (k) {
        LibraryKind.channel => l.kindChannels,
        LibraryKind.movie => l.navMovies,
        LibraryKind.series => l.navSeries,
      };

  List<Widget> _content(SourceLibrary lib, Map<String, Channel> channels) {
    final uids = lib.favoriteUids(_kind);

    if (_kind == LibraryKind.channel) {
      final items = [for (final u in uids) if (channels[u] != null) channels[u]!];
      if (items.isEmpty) return [_Empty(uids.isEmpty ? _hint(AppLocalizations.of(context), _kind) : AppLocalizations.of(context).favoritesNotInList)];
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => SizedBox(
              height: channelTileExtent,
              child: ChannelTile(
                channel: items[i],
                onTap: () => openPlayer(context, ref, items[i]),
              ),
            ),
          ),
        ),
      ];
    }

    final kind = _kind == LibraryKind.movie ? MediaKind.movies : MediaKind.series;
    final catalog = ref.watch(mediaCatalogProvider(kind));
    final byUid = ref.watch(mediaByUidProvider(kind));
    if (uids.isEmpty) return [_Empty(_hint(AppLocalizations.of(context), _kind))];
    if (catalog.isLoading && byUid.isEmpty) {
      return const [SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())))];
    }
    final items = [for (final u in uids) if (byUid[u] != null) byUid[u]!];
    if (items.isEmpty) return [_Empty(AppLocalizations.of(context).favoritesNotInCatalog)];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 0.54,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              PosterCard(entry: items[i], onTap: () => openMediaDetail(context, items[i])),
        ),
      ),
    ];
  }

  static String _hint(AppLocalizations l, LibraryKind k) => switch (k) {
        LibraryKind.channel => l.emptyFavoritesChannels,
        LibraryKind.movie => l.emptyFavoritesMovies,
        LibraryKind.series => l.emptyFavoritesSeries,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.onSync});
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
      child: Row(
        children: [
          Text(AppLocalizations.of(context).navFavorites,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: AppLocalizations.of(context).transferTooltip,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.sync_alt_rounded),
            onPressed: onSync,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
          ),
        ),
      );
}

/// Tarjeta de "Continuar viendo": póster con barra de progreso y botón para quitarla.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.entry});
  final ProgressEntry entry;

  void _resume(BuildContext context, WidgetRef ref) {
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).resumeNeedsXtream)));
      return;
    }
    final url = entry.isEpisode
        ? XtreamClient.episodeUrl(
            creds, Episode(id: entry.id, season: 0, number: 0, title: '', ext: entry.ext))
        : XtreamClient.movieUrl(
            creds, VodItem(id: entry.id, title: '', poster: '', group: '', ext: entry.ext));
    openPlayer(
      context,
      ref,
      Channel(
        index: -1,
        name: entry.isEpisode ? '${entry.title} · ${entry.subtitle}' : entry.title,
        url: url,
        group: entry.subtitle,
        isLive: false,
        stableId: entry.key,
        media: MediaMeta(
          id: entry.id,
          isEpisode: entry.isEpisode,
          ext: entry.ext,
          title: entry.title,
          poster: entry.poster,
          subtitle: entry.subtitle,
        ),
      ),
      startAt: entry.resumeAt,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 150,
        child: FocusRing(
          radius: 16,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _resume(context, ref),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColoredBox(
                          color: s.surfaceContainerHigh,
                          child: CachedImage(
                            url: entry.poster,
                            cacheWidth: 340,
                            fallback: Icon(Icons.movie_rounded, size: 40, color: s.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.fraction,
                            minHeight: 5,
                            semanticsLabel: AppLocalizations.of(context).commonProgress,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          tooltip: AppLocalizations.of(context).removeFromContinue,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: EdgeInsets.zero),
                          iconSize: 18,
                          color: Colors.white,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => ref.read(libraryProvider.notifier).hideProgress(entry.key),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(cleanTitle(entry.title),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(entry.subtitle.isEmpty ? AppLocalizations.of(context).movieLabel : entry.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
