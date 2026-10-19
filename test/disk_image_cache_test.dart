import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/cache/disk_image_cache.dart';

Uint8List _bytes(int n, [int v = 7]) => Uint8List.fromList(List.filled(n, v));

void main() {
  late Directory tmp;
  late int fetches;
  late Map<String, Uint8List?> remote;

  DiskImageCache make({int maxBytes = 1 << 20, int maxConcurrent = 6, int maxFile = 3 << 20}) =>
      DiskImageCache(
        directory: () async => Directory('${tmp.path}/logos'),
        fetcher: (url) async {
          fetches++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return remote[url];
        },
        maxBytes: maxBytes,
        maxConcurrent: maxConcurrent,
        maxFileBytes: maxFile,
      );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lumio_img_');
    fetches = 0;
    remote = {'http://a/1.png': _bytes(100), 'http://a/2.png': _bytes(200)};
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('descarga una vez y después sirve desde disco, también tras reiniciar', () async {
    final c = make();
    final f1 = await c.fetch('http://a/1.png');
    expect(f1, isNotNull);
    expect(f1!.lengthSync(), 100);
    await c.fetch('http://a/1.png');
    expect(fetches, 1);

    final reiniciada = make(); // otra sesión: la caché de disco persiste
    expect((await reiniciada.fetch('http://a/1.png'))!.lengthSync(), 100);
    expect(fetches, 1);
  });

  test('peticiones simultáneas de la misma URL comparten una sola descarga', () async {
    final c = make();
    final r = await Future.wait([for (var i = 0; i < 10; i++) c.fetch('http://a/1.png')]);
    expect(r.every((f) => f != null && f.path == r.first!.path), isTrue);
    expect(fetches, 1);
  });

  test('limita las descargas simultáneas', () async {
    var running = 0, peak = 0;
    final c = DiskImageCache(
      directory: () async => Directory('${tmp.path}/logos'),
      fetcher: (url) async {
        running++;
        if (running > peak) peak = running;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        running--;
        return _bytes(10);
      },
      maxConcurrent: 3,
    );
    await Future.wait([for (var i = 0; i < 12; i++) c.fetch('http://a/$i.png')]);
    expect(peak, lessThanOrEqualTo(3));
    expect(peak, greaterThan(1), reason: 'sí se hacen en paralelo');
  });

  test('un fallo no se reintenta en cada pasada y no rompe a los demás', () async {
    remote['http://a/rota.png'] = null;
    final c = make();
    expect(await c.fetch('http://a/rota.png'), isNull);
    expect(await c.fetch('http://a/rota.png'), isNull);
    expect(fetches, 1);
    expect(c.failedCount, 1);
    expect(await c.fetch('http://a/1.png'), isNotNull);
  });

  test('URL vacía, respuesta vacía o enorme: no se guarda', () async {
    remote['http://a/vacia.png'] = Uint8List(0);
    remote['http://a/enorme.png'] = _bytes(5000);
    final c = make(maxFile: 1000);
    expect(await c.fetch(''), isNull);
    expect(await c.fetch('http://a/vacia.png'), isNull);
    expect(await c.fetch('http://a/enorme.png'), isNull);
    final dir = Directory('${tmp.path}/logos');
    expect(!dir.existsSync() || dir.listSync().whereType<File>().isEmpty, isTrue,
        reason: 'no se debe haber guardado nada');
  });

  test('si el descargador lanza una excepción, devuelve null', () async {
    final c = DiskImageCache(
      directory: () async => Directory('${tmp.path}/logos'),
      fetcher: (url) async => throw const SocketException('sin red'),
    );
    expect(await c.fetch('http://a/1.png'), isNull);
  });

  test('prune borra lo más antiguo hasta bajar del límite', () async {
    remote = {for (var i = 0; i < 6; i++) 'http://a/$i.png': _bytes(1000, i)};
    final c = make(maxBytes: 4000);
    for (var i = 0; i < 6; i++) {
      final f = (await c.fetch('http://a/$i.png'))!;
      f.setLastModifiedSync(DateTime(2026, 1, 1 + i)); // 0 es la más antigua
    }
    await c.prune();
    final left = Directory('${tmp.path}/logos').listSync().whereType<File>().toList();
    final total = left.fold<int>(0, (a, f) => a + f.lengthSync());
    expect(total, lessThanOrEqualTo(4000 * 0.7));
    // lo más reciente se conserva
    final c2 = make(maxBytes: 4000);
    final before = fetches;
    await c2.fetch('http://a/5.png');
    expect(fetches, before, reason: 'la más reciente sigue en disco');
  });
}
