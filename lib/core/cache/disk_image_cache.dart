import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import '../util/stable_hash.dart';

/// Descarga una URL y devuelve sus bytes; `null` si falla.
typedef ImageFetcher = Future<Uint8List?> Function(String url);

/// Caché de imágenes en disco (logos de canales, pósteres).
///
/// - Cada URL se descarga una sola vez y se reutiliza entre pantallas y entre sesiones.
/// - Descargas simultáneas limitadas ([maxConcurrent]) y deduplicadas: 50 logos visibles a la
///   vez no abren 50 conexiones.
/// - Los fallos se recuerdan durante la sesión para no reintentar en cada desplazamiento.
/// - Mantiene el tamaño bajo [maxBytes] borrando lo menos usado (por fecha de acceso).
class DiskImageCache {
  DiskImageCache({
    required this.directory,
    required this.fetcher,
    this.maxBytes = 150 * 1024 * 1024,
    this.maxConcurrent = 6,
    this.maxFileBytes = 3 * 1024 * 1024,
  });

  final Future<Directory> Function() directory;
  final ImageFetcher fetcher;
  final int maxBytes;
  final int maxConcurrent;
  final int maxFileBytes;

  final _inFlight = <String, Future<File?>>{};
  final _failed = <String>{};
  final _queue = Queue<Completer<void>>();
  var _running = 0;
  var _pruned = false;

  /// Devuelve el fichero de la imagen (de disco o recién descargado); `null` si no se pudo.
  Future<File?> fetch(String url) {
    if (url.isEmpty || _failed.contains(url)) return Future.value(null);
    // OJO: el callback de whenComplete NO debe devolver la petición (remove la devuelve):
    // el Future se esperaría a sí mismo y no terminaría nunca.
    return _inFlight.putIfAbsent(url, () => _load(url).whenComplete(() {
          _inFlight.remove(url);
        }));
  }

  Future<File?> _load(String url) async {
    try {
      return await _loadUnsafe(url);
    } catch (_) {
      // Cualquier fallo (sin carpeta de caché, disco lleno…) no debe romper la pantalla.
      _failed.add(url);
      return null;
    }
  }

  Future<File?> _loadUnsafe(String url) async {
    final dir = await directory();
    final file = File('${dir.path}${Platform.pathSeparator}${stableHash(url)}');
    if (await file.exists()) {
      // Marca de uso para que la limpieza conserve lo reciente.
      unawaited(file.setLastModified(DateTime.now()).catchError((_) => null));
      return file;
    }

    await _acquire();
    try {
      if (await file.exists()) return file; // otra petición pudo completarla mientras esperaba
      final bytes = await fetcher(url);
      if (bytes == null || bytes.isEmpty || bytes.length > maxFileBytes) {
        _failed.add(url);
        return null;
      }
      await dir.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
      if (!_pruned) {
        _pruned = true;
        unawaited(prune());
      }
      return file;
    } catch (_) {
      _failed.add(url);
      return null;
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_running < maxConcurrent) {
      _running++;
      return;
    }
    final c = Completer<void>();
    _queue.add(c);
    await c.future; // quien libera nos pasa su plaza sin decrementar _running
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _running--;
    }
  }

  /// Borra lo menos usado hasta quedar al 70 % del límite.
  Future<void> prune() async {
    try {
      final dir = await directory();
      if (!await dir.exists()) return;
      final files = <(File, int, DateTime)>[];
      var total = 0;
      await for (final e in dir.list()) {
        if (e is! File || e.path.endsWith('.tmp')) continue;
        final stat = await e.stat();
        files.add((e, stat.size, stat.modified));
        total += stat.size;
      }
      if (total <= maxBytes) return;
      files.sort((a, b) => a.$3.compareTo(b.$3)); // más antiguo primero
      final target = (maxBytes * 0.7).toInt();
      for (final f in files) {
        if (total <= target) break;
        await f.$1.delete();
        total -= f.$2;
      }
    } catch (_) {}
  }

  /// Fallos recordados en esta sesión (para tests y diagnóstico).
  int get failedCount => _failed.length;
}

/// Descarga real por HTTP con tiempos de espera cortos.
Future<Uint8List?> httpFetchImage(String url) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..userAgent = 'Lumio';
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 10));
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      await res.drain<void>();
      return null;
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res.timeout(const Duration(seconds: 15))) {
      builder.add(chunk);
      if (builder.length > 4 * 1024 * 1024) return null; // demasiado grande para un logo
    }
    return builder.takeBytes();
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
