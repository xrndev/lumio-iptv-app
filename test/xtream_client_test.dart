import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_launcher/core/models/media.dart';
import 'package:iptv_launcher/core/network/xtream_client.dart';

void main() {
  test('normaliza el host', () {
    expect(XtreamCredentials(host: 'srv.example:8080/', username: 'u', password: 'p').host,
        'http://srv.example:8080');
    expect(XtreamCredentials(host: 'https://srv.example/player_api.php', username: 'u', password: 'p').host,
        'https://srv.example');
  });

  test('convierte get_live_streams en canales con categoría, catch-up y EPG', () {
    final c = XtreamCredentials(host: 'http://srv.example', username: 'u', password: 'p');
    const cats = '[{"category_id":"5","category_name":"Deportes"}]';
    const streams = '''[
      {"num":1,"name":"Canal A","stream_id":101,"stream_icon":"http://i/a.png","epg_channel_id":"a.es","category_id":"5","tv_archive":1,"tv_archive_duration":"3"},
      {"num":2,"name":"Canal B","stream_id":"102","category_id":"9","tv_archive":0},
      {"name":"sin id"}
    ]''';
    final p = XtreamClient.parseLive(streams, cats, c);

    expect(p.channels, hasLength(2));
    expect(p.skippedLines, 1);
    final a = p.channels[0];
    expect(a.url, 'http://srv.example/live/u/p/101.ts');
    expect(a.altUrl, 'http://srv.example/live/u/p/101.m3u8'); // respaldo si .ts no abre
    expect(a.group, 'Deportes');
    expect(a.tvgId, 'a.es');
    expect(a.catchup, 'xc');
    expect(a.catchupDays, 3);
    expect(p.channels[1].group, '');
    expect(p.channels[1].supportsCatchup, isFalse);
    expect(p.epgUrls.single, contains('xmltv.php?username=u'));
  });

  test('películas: categorías, valoración y extensión', () {
    const cats = '[{"category_id":"1","category_name":"VOD | SPANISH"},{"category_id":"2","category_name":"Vacía"}]';
    const items = '''[
      {"name":"ES - The Storm - 2026 (SUB)","stream_id":10,"stream_icon":"http://i/p.jpg","rating":"6.5","category_id":"1","container_extension":"mkv"},
      {"name":"Sin rating","stream_id":"11","rating":"0","category_id":"1","container_extension":""},
      {"name":"sin id"}
    ]''';
    final c = XtreamClient.parseMovies(items, cats);
    expect(c.items, hasLength(2));
    expect(c.groups, ['VOD | SPANISH']); // "Vacía" no tiene contenido
    final m = c.items[0] as VodItem;
    expect(m.ext, 'mkv');
    expect(m.rating, 6.5);
    expect(c.items[1].rating, isNull);
    expect((c.items[1] as VodItem).ext, 'mp4');
    expect(cleanTitle(m.title), 'The Storm');
    final creds = XtreamCredentials(host: 'srv', username: 'u', password: 'p');
    expect(XtreamClient.movieUrl(creds, m), 'http://srv/movie/u/p/10.mkv');
  });

  test('series: listado y episodios por temporada', () {
    final list = XtreamClient.parseSeries(
      '[{"series_id":5,"name":"Serie X","cover":"http://c.jpg","category_id":"3","releaseDate":"2026-10-15","backdrop_path":["http://b.jpg"],"rating":"7"}]',
      '[{"category_id":"3","category_name":"SRS | SPANISH"}]',
    );
    final s = list.items.single as SeriesItem;
    expect(s.year, '2026');
    expect(s.backdrop, 'http://b.jpg');

    final d = XtreamClient.parseSeriesInfo('''{
      "info":{"plot":"Trama","genre":"Drama"},
      "episodes":{"2":[{"id":"21","episode_num":2,"title":"X - S02E02 - Dos","container_extension":"mp4","info":{"duration_secs":120}},
                       {"id":"20","episode_num":1,"title":"X - S02E01 - Uno","container_extension":"mkv","info":{}}],
                  "1":[{"id":"10","episode_num":1,"title":"X - S01E01 - Piloto","season":1,"container_extension":"mp4","info":{}}]}
    }''');
    expect(d.seasons.keys.toList(), [1, 2]); // ordenadas
    expect(d.seasons[2]!.map((e) => e.number), [1, 2]); // episodios ordenados
    expect(d.seasons[2]!.last.durationSecs, 120);
    expect(d.plot, 'Trama');
    final creds = XtreamCredentials(host: 'srv', username: 'u', password: 'p');
    expect(XtreamClient.episodeUrl(creds, d.seasons[1]!.single), 'http://srv/series/u/p/10.mp4');
  });

  test('cuenta: caducidad y estado', () {
    final a = XtreamAccount.fromJson({'status': 'Active', 'exp_date': '1', 'max_connections': '2'});
    expect(a.isActive, isTrue);
    expect(a.isExpired, isTrue);
    expect(a.maxConnections, 2);
    expect(XtreamAccount.fromJson({'status': 'Active', 'exp_date': null}).expiry, isNull);
  });
}
