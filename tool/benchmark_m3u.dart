// Uso: dart run tool/benchmark_m3u.dart [numCanales=50000]
// Genera una lista sintética, la parsea en un Isolate y reporta tiempo y RSS.
import 'dart:io';

import 'package:iptv_launcher/core/parsing/m3u_parser.dart';

Future<void> main(List<String> args) async {
  final n = args.isNotEmpty ? int.parse(args.first) : 50000;
  final dir = Directory('.bench')..createSync();
  final file = File('${dir.path}/synthetic_$n.m3u');

  if (!file.existsSync()) {
    final sink = file.openWrite();
    sink.writeln('#EXTM3U url-tvg="http://epg.example/guide.xml.gz"');
    for (var i = 0; i < n; i++) {
      sink.writeln('#EXTINF:-1 tvg-id="ch$i.example" tvg-name="Canal $i" '
          'tvg-logo="http://logos.example/$i.png" group-title="Grupo ${i % 120}",Canal $i HD');
      sink.writeln('http://stream.example/live/user/pass/$i.m3u8');
    }
    await sink.close();
  }

  final sizeMb = file.lengthSync() / (1024 * 1024);
  final rssBefore = ProcessInfo.currentRss;
  final sw = Stopwatch()..start();
  final playlist = await M3uParser.parseFile(file.path);
  sw.stop();
  final rssAfter = ProcessInfo.currentRss;

  stdout
    ..writeln('canales:        ${playlist.channels.length}')
    ..writeln('grupos:         ${playlist.groups.length}')
    ..writeln('fichero:        ${sizeMb.toStringAsFixed(1)} MB')
    ..writeln('tiempo:         ${sw.elapsedMilliseconds} ms')
    ..writeln('RSS delta:      ${((rssAfter - rssBefore) / (1024 * 1024)).toStringAsFixed(1)} MB');
}
