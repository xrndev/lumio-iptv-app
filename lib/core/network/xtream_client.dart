import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';

import '../epg/epg.dart';
import '../models/channel.dart';
import '../models/media.dart';
import '../util/stable_hash.dart';

class XtreamCredentials {
  XtreamCredentials({required String host, required this.username, required this.password})
      : host = _normalize(host);

  /// `http(s)://host[:puerto]` sin barra final ni `/player_api.php`.
  final String host;
  final String username;
  final String password;

  static String _normalize(String raw) {
    var h = raw.trim();
    if (!h.contains('://')) h = 'http://$h';
    final uri = Uri.parse(h);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
}

class XtreamAccount {
  const XtreamAccount({
    required this.status,
    this.expiry,
    this.maxConnections,
    this.activeConnections,
    this.isTrial = false,
  });

  final String status;

  /// `null` = sin caducidad.
  final DateTime? expiry;
  final int? maxConnections;
  final int? activeConnections;
  final bool isTrial;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpired => expiry != null && expiry!.isBefore(DateTime.now());

  factory XtreamAccount.fromJson(Map<String, dynamic> userInfo) {
    final exp = int.tryParse('${userInfo['exp_date'] ?? ''}');
    return XtreamAccount(
      status: '${userInfo['status'] ?? 'unknown'}',
      expiry: exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      maxConnections: int.tryParse('${userInfo['max_connections'] ?? ''}'),
      activeConnections: int.tryParse('${userInfo['active_cons'] ?? ''}'),
      isTrial: '${userInfo['is_trial'] ?? '0'}' == '1',
    );
  }
}

class XtreamLoadResult {
  const XtreamLoadResult(this.account, this.playlist);
  final XtreamAccount account;
  final M3uPlaylist playlist;
}

/// Cliente de la API `player_api.php` de Xtream Codes (solo Live por ahora).
class XtreamClient {
  XtreamClient([Dio? dio, this._cacheDir])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 90),
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
            ));

  final Dio _dio;
  final Future<Directory> Function()? _cacheDir;

  /// [fresh] ignora la caché (acción explícita del usuario: añadir o recargar la cuenta).
  Future<XtreamLoadResult> loadLive(XtreamCredentials c, {bool fresh = false}) async {
    final ttl = fresh ? Duration.zero : const Duration(hours: 6);
    final info = await _get(c, null);
    final userInfo = (await Isolate.run(() => jsonDecode(info)) as Map)['user_info'];
    if (userInfo is! Map) {
      throw const FormatException('Respuesta inválida: credenciales o servidor incorrectos');
    }
    final account = XtreamAccount.fromJson(userInfo.cast<String, dynamic>());
    if (!account.isActive) throw StateError('Cuenta no activa (${account.status})');

    final cats = await _getCached(c, 'get_live_categories', ttl: ttl);
    final streams = await _getCached(c, 'get_live_streams', ttl: ttl);
    final playlist = await Isolate.run(() => parseLive(streams, cats, c));
    return XtreamLoadResult(account, playlist);
  }

  // --- VOD y series ---------------------------------------------------------

  Future<MediaCatalog> loadMovies(XtreamCredentials c) async {
    final cats = await _getCached(c, 'get_vod_categories');
    final items = await _getCached(c, 'get_vod_streams');
    return Isolate.run(() => parseMovies(items, cats));
  }

  Future<MediaCatalog> loadSeries(XtreamCredentials c) async {
    final cats = await _getCached(c, 'get_series_categories');
    final items = await _getCached(c, 'get_series');
    return Isolate.run(() => parseSeries(items, cats));
  }

  Future<VodDetail> vodInfo(XtreamCredentials c, int id) async {
    final body = await _get(c, 'get_vod_info', {'vod_id': '$id'});
    return Isolate.run(() => parseVodInfo(body));
  }

  /// Guía corta (programa actual y siguientes) de un canal en directo.
  Future<List<EpgProgram>> shortEpg(XtreamCredentials c, int streamId) async {
    final body = await _get(c, 'get_short_epg', {'stream_id': '$streamId', 'limit': '4'});
    return parseShortEpg(body);
  }

  Future<SeriesDetail> seriesInfo(XtreamCredentials c, int id) async {
    final body = await _get(c, 'get_series_info', {'series_id': '$id'});
    return Isolate.run(() => parseSeriesInfo(body));
  }

  static String movieUrl(XtreamCredentials c, VodItem m) =>
      '${c.host}/movie/${c.username}/${c.password}/${m.id}.${m.ext}';

  static String episodeUrl(XtreamCredentials c, Episode e) =>
      '${c.host}/series/${c.username}/${c.password}/${e.id}.${e.ext}';

  static String _s(Object? v) {
    final s = '${v ?? ''}'.trim();
    return s == 'null' ? '' : s;
  }

  /// `"2026-10-15"` → `"2026"`.
  static String _year(Object? v) {
    final s = _s(v);
    return s.length >= 4 ? s.substring(0, 4) : '';
  }

  static double? _rating(Object? v) {
    final r = double.tryParse(_s(v));
    return (r == null || r <= 0) ? null : r;
  }

  static Map<String, String> _categoryNames(String json) {
    final d = jsonDecode(json);
    return {
      if (d is List)
        for (final e in d.whereType<Map<String, dynamic>>())
          _s(e['category_id']): _s(e['category_name']),
    };
  }

  static MediaCatalog _catalog(List<MediaEntry> items, Map<String, String> cats) {
    final used = {for (final i in items) i.group};
    return MediaCatalog(
      items: items,
      groups: [
        for (final name in cats.values)
          if (used.contains(name)) name,
      ],
    );
  }

  static MediaCatalog parseMovies(String itemsJson, String catsJson) {
    final cats = _categoryNames(catsJson);
    final d = jsonDecode(itemsJson);
    final out = <MediaEntry>[];
    if (d is List) {
      for (final e in d) {
        if (e is! Map<String, dynamic> || e['stream_id'] == null) continue;
        final id = int.tryParse(_s(e['stream_id']));
        if (id == null) continue;
        final name = _s(e['name']);
        out.add(VodItem(
          id: id,
          title: name,
          poster: _s(e['stream_icon']),
          group: cats[_s(e['category_id'])] ?? '',
          ext: _s(e['container_extension']).isEmpty ? 'mp4' : _s(e['container_extension']),
          rating: _rating(e['rating']),
          year: _year(e['year'] ?? e['releaseDate']).isNotEmpty
              ? _year(e['year'] ?? e['releaseDate'])
              : (RegExp(r'\b((?:19|20)\d{2})\b').firstMatch(name)?.group(1) ?? ''),
        ));
      }
    }
    return _catalog(out, cats);
  }

  static MediaCatalog parseSeries(String itemsJson, String catsJson) {
    final cats = _categoryNames(catsJson);
    final d = jsonDecode(itemsJson);
    final out = <MediaEntry>[];
    if (d is List) {
      for (final e in d) {
        if (e is! Map<String, dynamic>) continue;
        final id = int.tryParse(_s(e['series_id']));
        if (id == null) continue;
        final backdrop = e['backdrop_path'];
        out.add(SeriesItem(
          id: id,
          title: _s(e['name']),
          poster: _s(e['cover']),
          group: cats[_s(e['category_id'])] ?? '',
          rating: _rating(e['rating']),
          year: _year(e['releaseDate'] ?? e['release_date']),
          plot: _s(e['plot']),
          genre: _s(e['genre']),
          backdrop: backdrop is List && backdrop.isNotEmpty ? _s(backdrop.first) : '',
        ));
      }
    }
    return _catalog(out, cats);
  }

  static VodDetail parseVodInfo(String body) {
    final d = jsonDecode(body);
    final info = d is Map ? d['info'] : null;
    if (info is! Map) return const VodDetail();
    final backdrop = info['backdrop_path'];
    return VodDetail(
      plot: _s(info['plot'] ?? info['description']),
      genre: _s(info['genre']),
      duration: _s(info['duration']),
      releaseDate: _s(info['releasedate'] ?? info['release_date']),
      cast: _s(info['cast'] ?? info['actors']),
      director: _s(info['director']),
      backdrop: backdrop is List && backdrop.isNotEmpty ? _s(backdrop.first) : '',
    );
  }

  static SeriesDetail parseSeriesInfo(String body) {
    final d = jsonDecode(body);
    if (d is! Map) return const SeriesDetail(seasons: {});
    final info = d['info'] is Map ? d['info'] as Map : const {};
    final backdrop = info['backdrop_path'];

    final seasons = <int, List<Episode>>{};
    final eps = d['episodes'];
    // El servidor devuelve un mapa {"1": [...]} (o a veces una lista de listas).
    final entries = eps is Map
        ? eps.entries.map((e) => MapEntry(_s(e.key), e.value))
        : eps is List
            ? eps.asMap().entries.map((e) => MapEntry('${e.key + 1}', e.value))
            : const <MapEntry<String, dynamic>>[];
    for (final entry in entries) {
      final list = entry.value;
      if (list is! List) continue;
      for (final e in list.whereType<Map<String, dynamic>>()) {
        final id = int.tryParse(_s(e['id']));
        if (id == null) continue;
        final season = int.tryParse(_s(e['season'])) ?? int.tryParse(entry.key) ?? 1;
        final einfo = e['info'] is Map ? e['info'] as Map : const {};
        seasons.putIfAbsent(season, () => []).add(Episode(
              id: id,
              season: season,
              number: int.tryParse(_s(e['episode_num'])) ?? 0,
              title: _s(e['title']),
              ext: _s(e['container_extension']).isEmpty ? 'mp4' : _s(e['container_extension']),
              durationSecs: int.tryParse(_s(einfo['duration_secs'])),
              plot: _s(einfo['plot']),
              image: _s(einfo['movie_image']),
            ));
      }
    }
    for (final l in seasons.values) {
      l.sort((a, b) => a.number.compareTo(b.number));
    }
    final sorted = Map.fromEntries(seasons.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return SeriesDetail(
      seasons: sorted,
      plot: _s(info['plot']),
      genre: _s(info['genre']),
      cast: _s(info['cast']),
      backdrop: backdrop is List && backdrop.isNotEmpty ? _s(backdrop.first) : '',
    );
  }

  /// Como [_get] pero con caché en disco (gzip): las listas grandes tardan segundos en
  /// bajar, así que se reutilizan [ttl] y, si la red falla, se usa la copia aunque sea vieja.
  Future<String> _getCached(XtreamCredentials c, String action,
      {Duration ttl = const Duration(hours: 6)}) async {
    final dirFn = _cacheDir;
    if (dirFn == null) return _get(c, action);
    File? file;
    try {
      final dir = await dirFn();
      file = File('${dir.path}${Platform.pathSeparator}xtream_${stableHash('${c.host}|${c.username}')}_$action.gz');
    } catch (_) {
      return _get(c, action);
    }
    String? stale;
    try {
      if (await file.exists()) {
        final text = utf8.decode(gzip.decode(await file.readAsBytes()));
        if (DateTime.now().difference(await file.lastModified()) < ttl) return text;
        stale = text;
      }
    } catch (_) {
      // caché ilegible: se ignora y se vuelve a descargar
    }
    try {
      final body = await _get(c, action);
      try {
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsBytes(gzip.encode(utf8.encode(body)), flush: true);
        await tmp.rename(file.path);
      } catch (_) {
        // guardar la caché es un extra
      }
      return body;
    } catch (_) {
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<String> _get(XtreamCredentials c, String? action,
      [Map<String, String> extra = const {}]) async {
    try {
      final r = await _dio.get<String>('${c.host}/player_api.php', queryParameters: {
        'username': c.username,
        'password': c.password,
        if (action != null) 'action': action,
        ...extra,
      });
      return r.data ?? '';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      throw StateError(code == null
          ? 'No se pudo conectar con ${c.host}'
          : 'El servidor respondió HTTP $code');
    }
  }

  /// Convierte `get_live_streams` en canales. Pura: se ejecuta en un Isolate y se testea.
  static M3uPlaylist parseLive(String streamsJson, String categoriesJson, XtreamCredentials c) {
    final decodedCats = jsonDecode(categoriesJson);
    final cats = <String, String>{
      if (decodedCats is List)
        for (final e in decodedCats.whereType<Map<String, dynamic>>())
          '${e['category_id']}': '${e['category_name']}',
    };
    final decoded = jsonDecode(streamsJson);
    final out = <Channel>[];
    var skipped = 0;
    if (decoded is List) {
      for (final e in decoded) {
        if (e is! Map<String, dynamic> || e['stream_id'] == null) {
          skipped++;
          continue;
        }
        final archive = '${e['tv_archive'] ?? '0'}' == '1';
        out.add(Channel(
          index: out.length,
          name: '${e['name'] ?? e['stream_id']}',
          url: '${c.host}/live/${c.username}/${c.password}/${e['stream_id']}.ts',
          altUrl: '${c.host}/live/${c.username}/${c.password}/${e['stream_id']}.m3u8',
          stableId: 'x${e['stream_id']}',
          tvgId: '${e['epg_channel_id'] ?? ''}',
          logo: '${e['stream_icon'] ?? ''}',
          group: cats['${e['category_id']}'] ?? '',
          number: int.tryParse('${e['num'] ?? ''}'),
          catchup: archive ? 'xc' : '',
          catchupDays: archive ? int.tryParse('${e['tv_archive_duration'] ?? ''}') : null,
        ));
      }
    }
    return M3uPlaylist(
      channels: out,
      epgUrls: ['${c.host}/xmltv.php?username=${c.username}&password=${c.password}'],
      skippedLines: skipped,
    );
  }
}

/// Aviso sobre la cuenta que conviene enseñar al usuario, o `null` si todo va bien.
/// Lógica pura (recibe la hora) para poder testearla.
String? accountNotice(XtreamAccount a, DateTime now) {
  if (!a.isActive) return 'Tu cuenta no está activa (${a.status}). Contacta con tu proveedor.';
  final exp = a.expiry;
  if (exp != null) {
    if (exp.isBefore(now)) return 'Tu suscripción ha caducado. Renueva con tu proveedor.';
    final days = exp.difference(now).inDays;
    if (days <= 7) {
      return days == 0
          ? 'Tu suscripción caduca hoy.'
          : 'Tu suscripción caduca en $days ${days == 1 ? 'día' : 'días'}.';
    }
  }
  return null;
}

/// Pista cuando un canal falla y la cuenta solo permite una conexión.
String? connectionHint(XtreamAccount? a) {
  if (a == null || a.maxConnections == null || a.maxConnections! > 1) return null;
  return 'Tu cuenta permite 1 sola conexión: si la usas en otro dispositivo, este canal puede no abrirse.';
}
