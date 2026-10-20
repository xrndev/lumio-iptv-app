import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_text.dart';
import '../../../core/library/library_data.dart';
import '../../../core/models/channel.dart';
import '../../../core/models/media.dart';
import '../../../core/network/xtream_client.dart';
import '../../../core/util/channel_names.dart';
import '../../../core/util/format.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/widgets/cached_logo.dart';
import '../../../design_system/widgets/focus_ring.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
import '../../library/library_providers.dart';
import '../../library/presentation/favorite_button.dart';
import '../../player/presentation/player_page.dart';
import '../../playlists/playlist_providers.dart';
import '../vod_providers.dart';

/// Abre la ficha de una película o serie.
Future<void> openMediaDetail(BuildContext context, MediaEntry entry) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => entry is VodItem
        ? MovieDetailPage(item: entry)
        : SeriesDetailPage(item: entry as SeriesItem),
  ));
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.backdrop, required this.child});

  final String backdrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop.isNotEmpty)
            Opacity(
              opacity: 0.28,
              child: CachedImage(
                  url: backdrop, fit: BoxFit.cover, cacheWidth: 1280, fallback: const SizedBox()),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [s.surface.withValues(alpha: 0.2), s.surface],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: child),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filledTonal(
                    tooltip: AppLocalizations.of(context).commonBack,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster(this.url);
  final String url;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: s.surfaceContainerHigh,
            child: url.isEmpty
                ? const Icon(Icons.movie_rounded, size: 56)
                : CachedImage(
                    url: url,
                    fit: BoxFit.cover,
                    cacheWidth: 520,
                    fallback: const Icon(Icons.movie_rounded, size: 56)),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: s.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
      ]),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
        onPressed: onPressed,
      );
}

// --- Película ---------------------------------------------------------------

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({super.key, required this.item});
  final VodItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(vodDetailProvider(item.id)).valueOrNull;
    final loading = ref.watch(vodDetailProvider(item.id)).isLoading;
    final s = Theme.of(context).colorScheme;

    final progress = ref.watch(currentLibraryProvider.select((l) => l.progressOf(item.uid)));
    final resumeAt = progress?.resumeAt;

    void play({Duration? startAt}) {
      final creds = ref.read(xtreamCredentialsProvider);
      if (creds == null) return;
      openPlayer(
        context,
        ref,
        Channel(
          index: -1,
          name: cleanTitle(item.title),
          url: XtreamClient.movieUrl(creds, item),
          group: item.group,
          isLive: false,
          stableId: item.uid,
          media: MediaMeta(
            id: item.id,
            isEpisode: false,
            ext: item.ext,
            title: cleanTitle(item.title),
            poster: item.poster,
          ),
        ),
        startAt: startAt,
      );
    }

    return _DetailScaffold(
      backdrop: detail?.backdrop ?? '',
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cleanTitle(item.title),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (item.rating != null) _Chip(Icons.star_rounded, item.rating!.toStringAsFixed(1)),
              if (item.year.isNotEmpty) _Chip(Icons.calendar_today_rounded, item.year),
              if (detail != null && detail.duration.isNotEmpty) _Chip(Icons.schedule_rounded, detail.duration),
              if (detail != null && detail.genre.isNotEmpty) _Chip(Icons.theater_comedy_rounded, detail.genre),
              if (item.group.isNotEmpty) _Chip(Icons.folder_outlined, prettyGroupName(item.group)),
              if (progress?.finished ?? false) _Chip(Icons.check_circle_outline_rounded, AppLocalizations.of(context).commonWatched),
            ]),
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (resumeAt != null) ...[
                _PlayButton(label: AppLocalizations.of(context).continueAt(formatClock(resumeAt)), onPressed: () => play(startAt: resumeAt)),
                OutlinedButton(onPressed: () => play(), child: Text(AppLocalizations.of(context).fromStart)),
              ] else
                _PlayButton(label: AppLocalizations.of(context).play, onPressed: play),
              FavoriteButton(kind: LibraryKind.movie, uid: item.uid, size: 28),
            ]),
            const SizedBox(height: 24),
            if (loading && detail == null)
              const LinearProgressIndicator()
            else ...[
              Text(
                (detail?.plot.isNotEmpty ?? false) ? detail!.plot : AppLocalizations.of(context).noPlot,
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
              if (detail != null && detail.cast.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).castLabel, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail.cast, style: const TextStyle(height: 1.4)),
              ],
              if (detail != null && detail.director.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).directorLabel, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail.director),
              ],
            ],
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 260, child: _Poster(item.poster)),
                    const SizedBox(width: 32),
                    Expanded(child: info),
                  ],
                )
              : Column(children: [
                  SizedBox(width: 200, child: _Poster(item.poster)),
                  const SizedBox(height: 24),
                  info,
                ]),
        );
      }),
    );
  }
}

// --- Serie ------------------------------------------------------------------

class SeriesDetailPage extends ConsumerStatefulWidget {
  const SeriesDetailPage({super.key, required this.item});
  final SeriesItem item;

  @override
  ConsumerState<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends ConsumerState<SeriesDetailPage> {
  int? _season;

  void _play(Episode e, {Duration? startAt}) {
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) return;
    final series = cleanTitle(widget.item.title);
    openPlayer(
      context,
      ref,
      Channel(
        index: -1,
        name: AppLocalizations.of(context).episodeName(series, e.season, e.number),
        url: XtreamClient.episodeUrl(creds, e),
        group: cleanEpisodeTitle(AppLocalizations.of(context), e, widget.item),
        isLive: false,
        stableId: 'e${e.id}',
        media: MediaMeta(
          id: e.id,
          isEpisode: true,
          ext: e.ext,
          title: series,
          poster: widget.item.poster,
          subtitle: AppLocalizations.of(context).seasonEpisode(e.season, e.number),
          seriesId: widget.item.id,
        ),
      ),
      startAt: startAt,
    );
  }

  /// Episodio de esta serie que se estaba viendo (el último empezado y sin terminar).
  (Episode, ProgressEntry)? _episodeToContinue(Map<int, List<Episode>> seasons, SourceLibrary lib) {
    (Episode, ProgressEntry)? best;
    for (final e in seasons.values.expand((l) => l)) {
      final p = lib.progressOf('e${e.id}');
      if (p == null || p.resumeAt == null) continue;
      if (best == null || p.t > best.$2.t) best = (e, p);
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final async = ref.watch(seriesDetailProvider(item.id));
    final detail = async.valueOrNull;
    final s = Theme.of(context).colorScheme;
    final plot = (detail?.plot.isNotEmpty ?? false) ? detail!.plot : item.plot;
    final seasons = detail?.seasons ?? const <int, List<Episode>>{};
    final current = _season ?? (seasons.isEmpty ? null : seasons.keys.first);
    final episodes = current == null ? const <Episode>[] : (seasons[current] ?? const <Episode>[]);
    final library = ref.watch(currentLibraryProvider);
    final resume = _episodeToContinue(seasons, library);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cleanTitle(item.title),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (item.rating != null) _Chip(Icons.star_rounded, item.rating!.toStringAsFixed(1)),
          if (item.year.isNotEmpty) _Chip(Icons.calendar_today_rounded, item.year),
          if (item.genre.isNotEmpty) _Chip(Icons.theater_comedy_rounded, item.genre),
          if (seasons.isNotEmpty) _Chip(Icons.layers_rounded, AppLocalizations.of(context).seasonsCount(seasons.length)),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (resume != null)
            _PlayButton(
              label: AppLocalizations.of(context).continueEpisode(resume.$1.season, resume.$1.number, formatClock(resume.$2.resumeAt!)),
              onPressed: () => _play(resume.$1, startAt: resume.$2.resumeAt),
            ),
          FavoriteButton(kind: LibraryKind.series, uid: item.uid, size: 28),
        ]),
        const SizedBox(height: 16),
        Text(plot.isEmpty ? AppLocalizations.of(context).noPlot : plot, style: const TextStyle(height: 1.5, fontSize: 15)),
        if (detail != null && detail.cast.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).castLabel, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail.cast),
        ],
      ],
    );

    return _DetailScaffold(
      backdrop: (detail?.backdrop.isNotEmpty ?? false) ? detail!.backdrop : item.backdrop,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 720;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
          children: [
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 220, child: _Poster(item.poster)),
                const SizedBox(width: 32),
                Expanded(child: info),
              ])
            else ...[
              Center(child: SizedBox(width: 180, child: _Poster(item.poster))),
              const SizedBox(height: 20),
              info,
            ],
            const SizedBox(height: 28),
            if (async.isLoading && detail == null)
              const LinearProgressIndicator()
            else if (async.hasError)
              Text(AppLocalizations.of(context).episodesLoadError(localizedError(AppLocalizations.of(context), async.error!)))
            else if (seasons.isEmpty)
              Text(AppLocalizations.of(context).noEpisodes)
            else ...[
              WheelScrollRow(
                padding: EdgeInsets.zero,
                children: [
                  for (final n in seasons.keys)
                    CategoryChip(
                      label: AppLocalizations.of(context).seasonN(n),
                      selected: n == current,
                      onTap: () => setState(() => _season = n),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final e in episodes)
                _EpisodeTile(
                  episode: e,
                  series: item,
                  progress: library.progressOf('e${e.id}'),
                  // Pulsar un episodio a medias lo reanuda; uno visto empieza de cero.
                  onTap: () => _play(e, startAt: library.progressOf('e${e.id}')?.resumeAt),
                ),
            ],
          ],
        );
      }),
    );
  }
}

/// "Serie - S01E01 - Episode 1" → "Episode 1".
String cleanEpisodeTitle(AppLocalizations l, Episode e, SeriesItem series) {
  var t = e.title;
  final m = RegExp(r'S\d+E\d+\s*[-–]\s*(.+)$', caseSensitive: false).firstMatch(t);
  if (m != null) t = m.group(1)!;
  t = t.trim();
  return t.isEmpty ? l.episodeN(e.number) : t;
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.series,
    required this.onTap,
    this.progress,
  });

  final Episode episode;
  final SeriesItem series;
  final VoidCallback onTap;
  final ProgressEntry? progress;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final mins = episode.durationSecs == null ? null : (episode.durationSecs! / 60).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FocusRing(
        radius: 16,
        child: GlassCard(
        radius: 16,
        blur: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('${episode.number}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cleanEpisodeTitle(AppLocalizations.of(context), episode, series),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (episode.plot.isNotEmpty)
                        Text(episode.plot,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                      if (progress != null && !progress!.finished && progress!.fraction > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress!.fraction,
                              minHeight: 4,
                              semanticsLabel: AppLocalizations.of(context).episodeProgress,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (mins != null && mins > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text('$mins min', style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                if (progress?.finished ?? false)
                  Tooltip(
                    message: AppLocalizations.of(context).commonWatched,
                    child: Icon(Icons.check_circle_rounded, color: s.secondary, size: 32),
                  )
                else
                  Icon(Icons.play_circle_fill_rounded, color: s.primary, size: 32),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
