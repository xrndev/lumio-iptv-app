import 'package:flutter_test/flutter_test.dart';
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
    expect(a.group, 'Deportes');
    expect(a.tvgId, 'a.es');
    expect(a.catchup, 'xc');
    expect(a.catchupDays, 3);
    expect(p.channels[1].group, '');
    expect(p.channels[1].supportsCatchup, isFalse);
    expect(p.epgUrls.single, contains('xmltv.php?username=u'));
  });

  test('cuenta: caducidad y estado', () {
    final a = XtreamAccount.fromJson({'status': 'Active', 'exp_date': '1', 'max_connections': '2'});
    expect(a.isActive, isTrue);
    expect(a.isExpired, isTrue);
    expect(a.maxConnections, 2);
    expect(XtreamAccount.fromJson({'status': 'Active', 'exp_date': null}).expiry, isNull);
  });
}
