import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/channel.dart';
import '../../core/models/media.dart';
import '../playlists/playlist_providers.dart';

/// Catálogo completo por tipo. `null` si la fuente activa no es Xtream.
/// Se cachea mientras no cambien las credenciales.
final mediaCatalogProvider = FutureProvider.family<MediaCatalog?, MediaKind>((ref, kind) async {
  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) return null;
  final client = ref.watch(xtreamClientProvider);
  return kind == MediaKind.movies ? client.loadMovies(creds) : client.loadSeries(creds);
});

final mediaSearchProvider = StateProvider.family<String, MediaKind>((ref, kind) => '');
final mediaGroupProvider = StateProvider.family<String?, MediaKind>((ref, kind) => null);

final visibleMediaProvider = Provider.family<List<MediaEntry>, MediaKind>((ref, kind) {
  final all = ref.watch(mediaCatalogProvider(kind)).valueOrNull?.items ?? const <MediaEntry>[];
  final q = ref.watch(mediaSearchProvider(kind)).trim().toLowerCase();
  final group = ref.watch(mediaGroupProvider(kind));
  if (q.isEmpty && group == null) return all;
  return all
      .where((m) => (group == null || m.group == group) && (q.isEmpty || m.title.toLowerCase().contains(q)))
      .toList(growable: false);
});

final vodDetailProvider = FutureProvider.family<VodDetail, int>((ref, id) async {
  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) return const VodDetail();
  return ref.watch(xtreamClientProvider).vodInfo(creds, id);
});

final seriesDetailProvider = FutureProvider.family<SeriesDetail, int>((ref, id) async {
  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) return const SeriesDetail(seasons: {});
  return ref.watch(xtreamClientProvider).seriesInfo(creds, id);
});

/// Término de la búsqueda global (canales + películas + series).
final globalSearchProvider = StateProvider<String>((ref) => '');

class GlobalResults {
  const GlobalResults({this.channels = const [], this.movies = const [], this.series = const []});
  final List<Channel> channels;
  final List<MediaEntry> movies;
  final List<MediaEntry> series;
  bool get isEmpty => channels.isEmpty && movies.isEmpty && series.isEmpty;
}

/// Máximo de resultados por sección (la UI ofrece "ver todo" en cada pestaña).
const globalResultLimit = 40;

final globalResultsProvider = Provider<GlobalResults>((ref) {
  final q = ref.watch(globalSearchProvider).trim().toLowerCase();
  if (q.length < 2) return const GlobalResults();

  bool hit(String s) => s.toLowerCase().contains(q);
  final channels = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  final movies = ref.watch(mediaCatalogProvider(MediaKind.movies)).valueOrNull?.items ?? const <MediaEntry>[];
  final series = ref.watch(mediaCatalogProvider(MediaKind.series)).valueOrNull?.items ?? const <MediaEntry>[];

  return GlobalResults(
    channels: channels.where((c) => hit(c.name)).take(globalResultLimit).toList(),
    movies: movies.where((m) => hit(m.title)).take(globalResultLimit).toList(),
    series: series.where((m) => hit(m.title)).take(globalResultLimit).toList(),
  );
});
