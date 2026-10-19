// Uso: IPTV_XTREAM="http://host|usuario|contraseña" dart run tool/probe_xtream.dart
// Comprueba el cliente Xtream contra un servidor real (sin guardar credenciales).
import 'dart:io';

import 'package:iptv_launcher/core/models/media.dart';
import 'package:iptv_launcher/core/network/xtream_client.dart';

Future<void> main() async {
  final raw = Platform.environment['IPTV_XTREAM']?.split('|');
  if (raw == null || raw.length != 3) {
    stderr.writeln('Define IPTV_XTREAM="host|usuario|contraseña"');
    exit(2);
  }
  final c = XtreamCredentials(host: raw[0], username: raw[1], password: raw[2]);
  final client = XtreamClient();
  final sw = Stopwatch()..start();

  Future<T> timed<T>(String label, Future<T> Function() f) async {
    sw.reset();
    sw.start();
    final r = await f();
    stdout.writeln('$label: ${sw.elapsedMilliseconds} ms');
    return r;
  }

  final live = await timed('live', () => client.loadLive(c));
  stdout.writeln('  cuenta ${live.account.status}, canales ${live.playlist.channels.length}');

  final movies = await timed('películas', () => client.loadMovies(c));
  stdout.writeln('  ${movies.items.length} películas, ${movies.groups.length} categorías: ${movies.groups.take(3).join(' | ')}');
  final m = movies.items.whereType<VodItem>().first;
  stdout.writeln('  ej: "${cleanTitle(m.title)}" (${m.ext}) rating=${m.rating} año="${m.year}" poster=${m.poster.isNotEmpty}');
  final vi = await timed('ficha película', () => client.vodInfo(c, m.id));
  stdout.writeln('  sinopsis=${vi.plot.length} chars, duración=${vi.duration}, género=${vi.genre}');

  final series = await timed('series', () => client.loadSeries(c));
  stdout.writeln('  ${series.items.length} series, ${series.groups.length} categorías: ${series.groups.take(3).join(' | ')}');
  final s = series.items.whereType<SeriesItem>().firstWhere((e) => e.group.contains('SPANISH'), orElse: () => series.items.first as SeriesItem);
  final det = await timed('ficha serie', () => client.seriesInfo(c, s.id));
  stdout.writeln('  "${cleanTitle(s.title)}": ${det.seasons.length} temporadas, '
      '${det.seasons.values.fold<int>(0, (a, l) => a + l.length)} episodios');
  if (det.seasons.isNotEmpty) {
    final e = det.seasons.values.first.first;
    stdout.writeln('  primer episodio: T${e.season}E${e.number} ext=${e.ext}');
  }
  exit(0);
}
