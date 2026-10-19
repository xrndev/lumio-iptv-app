import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/epg/epg.dart';

String b(String s) => base64.encode(utf8.encode(s));

void main() {
  final t0 = DateTime(2026, 10, 19, 20).millisecondsSinceEpoch ~/ 1000;
  final body = jsonEncode({
    'epg_listings': [
      {'title': b('Telediario'), 'start_timestamp': '${t0 + 3600}', 'stop_timestamp': '${t0 + 7200}', 'description': b('Noticias')},
      {'title': b('La película'), 'start_timestamp': '$t0', 'stop_timestamp': '${t0 + 3600}'},
      {'title': '', 'start_timestamp': '1', 'stop_timestamp': '2'},
    ]
  });

  test('parsea, ordena y descarta entradas vacías', () {
    final p = parseShortEpg(body);
    expect(p.map((e) => e.title), ['La película', 'Telediario']);
    expect(p.last.description, 'Noticias');
  });

  test('ahora y después', () {
    final p = parseShortEpg(body);
    final now = DateTime.fromMillisecondsSinceEpoch((t0 + 1800) * 1000);
    final nn = nowNext(p, now);
    expect(nn.now!.title, 'La película');
    expect(nn.next!.title, 'Telediario');
    expect(nn.now!.progress(now), closeTo(0.5, 0.01));
  });

  test('basura no rompe', () {
    expect(parseShortEpg('no es json'), isEmpty);
    expect(parseShortEpg('{}'), isEmpty);
    expect(nowNext(const [], DateTime.now()).now, isNull);
  });
}
