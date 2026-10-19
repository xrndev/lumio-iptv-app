import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Descarga listas a disco en streaming (nunca a memoria) con reintentos.
///
/// La copia vive en el directorio de datos de la app (no en temporales) para que,
/// si al abrir la app no hay red, se pueda usar la última lista descargada.
class PlaylistDownloader {
  PlaylistDownloader([Dio? dio, Future<Directory> Function()? baseDir])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              // Algunos proveedores bloquean user-agents desconocidos.
              headers: {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
            )),
        _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Dio _dio;
  final Future<Directory> Function() _baseDir;

  Future<File> _target(String url) async {
    final dir = Directory('${(await _baseDir()).path}/playlists');
    await dir.create(recursive: true);
    return File('${dir.path}/playlist_${url.hashCode.toUnsigned(32)}.m3u');
  }

  /// Devuelve el fichero descargado; si falla la red y hay copia previa, esa copia.
  Future<File> download(String url, {int retries = 3}) async {
    final file = await _target(url);
    final partial = File('${file.path}.part');
    Object? lastError;
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        await _dio.download(url, partial.path);
        return await partial.rename(file.path); // sustituye la copia vieja
      } on DioException catch (e) {
        lastError = e;
        // 4xx no se reintenta (credenciales/URL erróneas).
        final code = e.response?.statusCode ?? 0;
        if (code >= 400 && code < 500) break;
        await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
      }
    }
    if (await partial.exists()) await partial.delete();
    if (await file.exists()) return file; // sin red: última copia buena
    throw HttpException('No se pudo descargar la lista: $lastError');
  }
}
