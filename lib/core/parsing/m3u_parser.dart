import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../models/channel.dart';

final _attrRe = RegExp(r'([\w-]+)="([^"]*)"');

/// Parser M3U/M3U8 en streaming.
///
/// - Procesa línea a línea: memoria constante respecto al tamaño del fichero
///   (solo se retienen los `Channel`).
/// - [parseFile] corre en un Isolate: la UI no se bloquea con 50k+ canales.
/// - Deduplica (intern) grupos, logos y user-agents repetidos.
class M3uParser {
  const M3uParser._();

  /// Parsea un fichero local en un Isolate de fondo.
  static Future<M3uPlaylist> parseFile(String path) => Isolate.run(() {
        final lines = File(path)
            .openRead()
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter());
        return parseLines(lines);
      });

  /// Parsea texto en un Isolate (para listas pequeñas ya en memoria).
  static Future<M3uPlaylist> parseStringInIsolate(String content) =>
      Isolate.run(() => parseString(content));

  /// Parsea texto de forma síncrona (tests, listas pequeñas).
  static M3uPlaylist parseString(String content) {
    final state = _ParseState();
    for (final line in const LineSplitter().convert(content)) {
      state.feed(line);
    }
    return state.finish();
  }

  /// Parsea un stream de líneas.
  static Future<M3uPlaylist> parseLines(Stream<String> lines) async {
    final state = _ParseState();
    await for (final line in lines) {
      state.feed(line);
    }
    return state.finish();
  }
}

/// Máquina de estados: un `#EXTINF` queda pendiente hasta la siguiente URL.
class _ParseState {
  final _channels = <Channel>[];
  final _epgUrls = <String>[];
  final _intern = <String, String>{};
  int _skipped = 0;

  _Extinf? _pending;
  String? _groupOverride; // #EXTGRP
  String? _userAgent; // #EXTVLCOPT:http-user-agent
  String? _referrer; // #EXTVLCOPT:http-referrer

  String _i(String s) => s.isEmpty ? s : (_intern[s] ??= s);

  void feed(String raw) {
    final line = raw.trim();
    if (line.isEmpty) return;

    if (line.codeUnitAt(0) == 0x23 /* # */) {
      if (line.startsWith('#EXTINF:')) {
        if (_pending != null) _skipped++; // EXTINF anterior sin URL
        _pending = _Extinf.parse(line);
        _groupOverride = null;
        _userAgent = null;
        _referrer = null;
      } else if (line.startsWith('#EXTM3U')) {
        final attrs = _attributes(line);
        final epg = attrs['url-tvg'] ?? attrs['x-tvg-url'];
        if (epg != null && epg.isNotEmpty) {
          _epgUrls.addAll(epg.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
      } else if (line.startsWith('#EXTGRP:')) {
        _groupOverride = line.substring(8).trim();
      } else if (line.startsWith('#EXTVLCOPT:')) {
        final opt = line.substring(11);
        final eq = opt.indexOf('=');
        if (eq > 0) {
          final key = opt.substring(0, eq).toLowerCase();
          final value = opt.substring(eq + 1).trim();
          if (key == 'http-user-agent') _userAgent = value;
          if (key == 'http-referrer' || key == 'http-referer') _referrer = value;
        }
      }
      return;
    }

    // Línea de URL.
    final info = _pending;
    if (info == null) {
      _skipped++; // URL suelta sin EXTINF
      return;
    }
    _pending = null;
    final a = info.attrs;
    _channels.add(Channel(
      index: _channels.length,
      name: info.name.isEmpty ? (a['tvg-name'] ?? line) : info.name,
      url: line,
      tvgId: a['tvg-id'] ?? '',
      tvgName: a['tvg-name'] ?? '',
      logo: _i(a['tvg-logo'] ?? ''),
      group: _i(a['group-title'] ?? _groupOverride ?? ''),
      number: int.tryParse(a['tvg-chno'] ?? a['channel-number'] ?? ''),
      catchup: _i(a['catchup'] ?? a['catchup-type'] ?? ''),
      catchupDays: int.tryParse(a['catchup-days'] ?? ''),
      catchupSource: a['catchup-source'] ?? '',
      userAgent: _i(_userAgent ?? a['http-user-agent'] ?? '').ifEmpty,
      referrer: _i(_referrer ?? a['http-referrer'] ?? '').ifEmpty,
    ));
  }

  M3uPlaylist finish() {
    if (_pending != null) _skipped++;
    return M3uPlaylist(channels: _channels, epgUrls: _epgUrls, skippedLines: _skipped);
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}

Map<String, String> _attributes(String s) =>
    {for (final m in _attrRe.allMatches(s)) m.group(1)!.toLowerCase(): m.group(2)!};

class _Extinf {
  _Extinf(this.attrs, this.name);

  final Map<String, String> attrs;
  final String name;

  /// `#EXTINF:-1 tvg-id="x" group-title="A, B",Nombre` → el nombre va tras la
  /// última coma que NO está entre comillas.
  static _Extinf parse(String line) {
    var inQuotes = false;
    var comma = -1;
    for (var i = 8; i < line.length; i++) {
      final c = line.codeUnitAt(i);
      if (c == 0x22 /* " */) {
        inQuotes = !inQuotes;
      } else if (c == 0x2C /* , */ && !inQuotes) {
        comma = i;
      }
    }
    final head = comma < 0 ? line : line.substring(0, comma);
    final name = comma < 0 ? '' : line.substring(comma + 1).trim();
    return _Extinf(_attributes(head), name);
  }
}
