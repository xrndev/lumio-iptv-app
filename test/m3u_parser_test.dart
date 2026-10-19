import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/parsing/m3u_parser.dart';

void main() {
  test('parsea atributos, comas dentro de comillas y cabecera EPG', () {
    const m3u = '''
#EXTM3U url-tvg="http://epg.example/a.xml.gz,http://epg.example/b.xml"
#EXTINF:-1 tvg-id="la1.es" tvg-name="La 1" tvg-logo="http://l/1.png" group-title="TDT, Nacional" tvg-chno="1" catchup="default" catchup-days="3",La 1 HD
http://s.example/1.m3u8
#EXTINF:-1,Sin atributos
#EXTGRP:Deportes
#EXTVLCOPT:http-user-agent=Custom/1.0
#EXTVLCOPT:http-referrer=http://ref.example
http://s.example/2.ts
''';
    final p = M3uParser.parseString(m3u);

    expect(p.epgUrls, ['http://epg.example/a.xml.gz', 'http://epg.example/b.xml']);
    expect(p.channels, hasLength(2));

    final c = p.channels[0];
    expect(c.name, 'La 1 HD');
    expect(c.tvgId, 'la1.es');
    expect(c.group, 'TDT, Nacional');
    expect(c.number, 1);
    expect(c.catchupDays, 3);
    expect(c.supportsCatchup, isTrue);

    final d = p.channels[1];
    expect(d.name, 'Sin atributos');
    expect(d.group, 'Deportes');
    expect(d.userAgent, 'Custom/1.0');
    expect(d.referrer, 'http://ref.example');
    expect(d.supportsCatchup, isFalse);
  });

  test('descarta entradas malformadas sin romper', () {
    const m3u = '''
#EXTM3U
http://huerfana.example/x.ts
#EXTINF:-1,Sin URL
#EXTINF:-1,Con URL
http://s.example/ok.ts
''';
    final p = M3uParser.parseString(m3u);
    expect(p.channels.map((c) => c.name), ['Con URL']);
    expect(p.skippedLines, 2);
  });

  test('tolera CRLF, líneas vacías y fichero vacío', () {
    expect(M3uParser.parseString('').channels, isEmpty);
    final p = M3uParser.parseString('#EXTM3U\r\n\r\n#EXTINF:-1,A\r\nhttp://a\r\n');
    expect(p.channels.single.url, 'http://a');
  });
}
