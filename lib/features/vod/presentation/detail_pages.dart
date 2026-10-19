import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/channel.dart';
import '../../../core/models/media.dart';
import '../../../core/network/xtream_client.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
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
              child: Image.network(backdrop,
                  fit: BoxFit.cover, cacheWidth: 1280, errorBuilder: (_, __, ___) => const SizedBox()),
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
                    tooltip: 'Volver',
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
                : Image.network(url,
                    fit: BoxFit.cover,
                    cacheWidth: 520,
                    errorBuilder: (_, __, ___) => const Icon(Icons.movie_rounded, size: 56)),
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

    void play() {
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
        ),
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
              if (item.group.isNotEmpty) _Chip(Icons.folder_outlined, item.group),
            ]),
            const SizedBox(height: 20),
            _PlayButton(label: 'Reproducir', onPressed: play),
            const SizedBox(height: 24),
            if (loading && detail == null)
              const LinearProgressIndicator()
            else ...[
              Text(
                (detail?.plot.isNotEmpty ?? false) ? detail!.plot : 'Sin sinopsis disponible.',
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
              if (detail != null && detail.cast.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Reparto', style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(detail.cast, style: const TextStyle(height: 1.4)),
              ],
              if (detail != null && detail.director.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Dirección', style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
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

  void _play(Episode e) {
    final creds = ref.read(xtreamCredentialsProvider);
    if (creds == null) return;
    final label = 'T${e.season} E${e.number}';
    openPlayer(
      context,
      ref,
      Channel(
        index: -1,
        name: '${cleanTitle(widget.item.title)} · $label',
        url: XtreamClient.episodeUrl(creds, e),
        group: cleanEpisodeTitle(e, widget.item),
        isLive: false,
      ),
    );
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
          if (seasons.isNotEmpty) _Chip(Icons.layers_rounded, '${seasons.length} temporadas'),
        ]),
        const SizedBox(height: 16),
        Text(plot.isEmpty ? 'Sin sinopsis disponible.' : plot, style: const TextStyle(height: 1.5, fontSize: 15)),
        if (detail != null && detail.cast.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Reparto', style: TextStyle(color: s.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
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
              Text('No se pudieron cargar los episodios: ${async.error}')
            else if (seasons.isEmpty)
              const Text('Esta serie no tiene episodios disponibles.')
            else ...[
              WheelScrollRow(
                padding: EdgeInsets.zero,
                children: [
                  for (final n in seasons.keys)
                    CategoryChip(
                      label: 'Temporada $n',
                      selected: n == current,
                      onTap: () => setState(() => _season = n),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final e in episodes) _EpisodeTile(episode: e, series: item, onTap: () => _play(e)),
            ],
          ],
        );
      }),
    );
  }
}

/// "Serie - S01E01 - Episode 1" → "Episode 1".
String cleanEpisodeTitle(Episode e, SeriesItem series) {
  var t = e.title;
  final m = RegExp(r'S\d+E\d+\s*[-–]\s*(.+)$', caseSensitive: false).firstMatch(t);
  if (m != null) t = m.group(1)!;
  t = t.trim();
  return t.isEmpty ? 'Episodio ${e.number}' : t;
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.series, required this.onTap});

  final Episode episode;
  final SeriesItem series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final mins = episode.durationSecs == null ? null : (episode.durationSecs! / 60).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                      Text(cleanEpisodeTitle(episode, series),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (episode.plot.isNotEmpty)
                        Text(episode.plot,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                if (mins != null && mins > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text('$mins min', style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.play_circle_fill_rounded, color: s.primary, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
