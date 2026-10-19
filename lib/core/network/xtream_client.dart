import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';

import '../models/channel.dart';

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
  XtreamClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 90),
              responseType: ResponseType.plain,
              headers: {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
            ));

  final Dio _dio;

  Future<XtreamLoadResult> loadLive(XtreamCredentials c) async {
    final info = await _get(c, null);
    final userInfo = (await Isolate.run(() => jsonDecode(info)) as Map)['user_info'];
    if (userInfo is! Map) {
      throw const FormatException('Respuesta inválida: credenciales o servidor incorrectos');
    }
    final account = XtreamAccount.fromJson(userInfo.cast<String, dynamic>());
    if (!account.isActive) throw StateError('Cuenta no activa (${account.status})');

    final cats = await _get(c, 'get_live_categories');
    final streams = await _get(c, 'get_live_streams');
    final playlist = await Isolate.run(() => parseLive(streams, cats, c));
    return XtreamLoadResult(account, playlist);
  }

  Future<String> _get(XtreamCredentials c, String? action) async {
    try {
      final r = await _dio.get<String>('${c.host}/player_api.php', queryParameters: {
        'username': c.username,
        'password': c.password,
        if (action != null) 'action': action,
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
