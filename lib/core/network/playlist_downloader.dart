import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Descarga listas a disco en streaming (nunca a memoria) con reintentos.
class PlaylistDownloader {
  PlaylistDownloader([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              // Algunos proveedores bloquean user-agents desconocidos.
              headers: {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
            ));

  final Dio _dio;

  /// Devuelve el fichero descargado. `.gz` se descomprime al parsear (EPG).
  Future<File> download(String url, {int retries = 3}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/playlist_${url.hashCode.toUnsigned(32)}.m3u');
    Object? lastError;
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        await _dio.download(url, file.path);
        return file;
      } on DioException catch (e) {
        lastError = e;
        // 4xx no se reintenta (credenciales/URL erróneas).
        final code = e.response?.statusCode ?? 0;
        if (code >= 400 && code < 500) break;
        await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
      }
    }
    throw HttpException('No se pudo descargar la lista: $lastError');
  }
}
