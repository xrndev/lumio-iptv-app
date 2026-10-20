import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/errors.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';

/// Simula un llavero que rechaza escribir y borrar (p. ej. macOS sin entitlement, -34018).
class _BrokenStore extends MemorySourceStore {
  @override
  Future<void> write(SavedSource source) async => throw StateError('-34018 sin entitlement');
  @override
  Future<void> clear() async => throw StateError('-34018 sin entitlement');
}

ProviderContainer _boot(SourceStore store) {
  final c = ProviderContainer(overrides: [sourceStoreProvider.overrideWithValue(store)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late Directory tmp;
  late String m3u;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('iptv_persist_');
    m3u = '${tmp.path}/lista.m3u';
    File(m3u).writeAsStringSync('#EXTM3U\n#EXTINF:-1,Canal A\nhttp://a\n#EXTINF:-1,Canal B\nhttp://b\n');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('SavedSource: JSON ida y vuelta y etiqueta sin secretos', () {
    const s = SavedSource.xtream(host: 'http://srv.example:80', username: 'joan', password: 'secreto');
    final back = SavedSource.fromJson(s.toJson())!;
    expect(back.type, SourceType.xtream);
    expect(back.password, 'secreto');
    expect(s.label, contains('srv.example'));
    expect(s.label, isNot(contains('secreto')));
    expect(const SavedSource.url('http://h.example/get.php?token=ABC').label, isNot(contains('ABC')));
    expect(SavedSource.fromJson({'type': 'raro', 'location': 'x'}), isNull);
    expect(SavedSource.fromJson('basura'), isNull);
  });

  test('la fuente se guarda al cargarla y se restaura al reiniciar la app', () async {
    final store = MemorySourceStore();

    final first = _boot(store);
    await first.read(playlistProvider.future);
    await first.read(playlistProvider.notifier).loadFile(m3u);
    expect(first.read(playlistProvider).value!.channels, hasLength(2));
    expect(store.value?.location, m3u);

    // "Cerrar y abrir": contenedor nuevo con el mismo almacén.
    final second = _boot(store);
    final restored = await second.read(playlistProvider.future);
    expect(restored!.channels.map((c) => c.name), ['Canal A', 'Canal B']);
    await Future<void>.delayed(Duration.zero); // microtask de _apply
    expect(second.read(activeSourceProvider)?.location, m3u);
  });

  test('solo clear() borra la fuente guardada', () async {
    final store = MemorySourceStore(SavedSource.file(m3u));
    final c = _boot(store);
    await c.read(playlistProvider.future);

    await c.read(playlistProvider.notifier).clear();
    expect(store.value, isNull);
    expect(c.read(playlistProvider).value, isNull);

    final next = _boot(store);
    expect(await next.read(playlistProvider.future), isNull);
  });

  test('una fuente nueva que falla no borra la guardada', () async {
    final store = MemorySourceStore(SavedSource.file(m3u));
    final c = _boot(store);
    await c.read(playlistProvider.future);

    await c.read(playlistProvider.notifier).loadFile('${tmp.path}/no_existe.m3u');
    expect(c.read(playlistProvider).hasError, isTrue);
    expect(store.value?.location, m3u); // la anterior sigue guardada

    final next = _boot(store);
    expect((await next.read(playlistProvider.future))!.channels, hasLength(2));
  });

  group('fuente precargada en la compilación', () {
    ProviderContainer boot(SourceStore store, String preset) {
      final c = ProviderContainer(overrides: [
        sourceStoreProvider.overrideWithValue(store),
        buildPresetProvider.overrideWithValue(preset),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    // El host de prueba no existe: abrir la fuente falla, pero eso no importa aquí.
    final preset = base64.encode(utf8.encode('http://127.0.0.1:9|usuario|clave'));

    test('por defecto (vacía) no hace nada', () async {
      final store = MemorySourceStore();
      expect(await boot(store, '').read(playlistProvider.future), isNull);
      expect(store.value, isNull);
    });

    test('se aplica en el primer arranque y se guarda', () async {
      final store = MemorySourceStore();
      await boot(store, preset).read(playlistProvider.future).catchError((_) => null);
      expect(store.value?.type, SourceType.xtream);
      expect(store.value?.username, 'usuario');
      expect(await store.presetApplied(), isTrue);
    });

    test('si el usuario la borra, no reaparece al reiniciar', () async {
      final store = MemorySourceStore();
      final first = boot(store, preset);
      await first.read(playlistProvider.future).catchError((_) => null);
      await first.read(playlistProvider.notifier).clear();
      expect(store.value, isNull);

      final second = boot(store, preset); // "reinicio" con la misma build
      expect(await second.read(playlistProvider.future), isNull);
      expect(store.value, isNull);
    });

    test('un valor mal formado se ignora', () async {
      for (final bad in ['no es base64!', base64.encode(utf8.encode('solo-un-campo'))]) {
        final store = MemorySourceStore();
        expect(await boot(store, bad).read(playlistProvider.future), isNull);
        expect(store.value, isNull);
      }
    });
  });

  test('si el almacén seguro falla al guardar, la lista se carga igualmente', () async {
    final store = _BrokenStore();
    final c = _boot(store);
    await c.read(playlistProvider.future);
    await c.read(playlistProvider.notifier).loadFile(m3u);
    expect(c.read(playlistProvider).hasError, isFalse);
    expect(c.read(playlistProvider).value!.channels, hasLength(2));
    // y borrar tampoco revienta aunque el almacén falle
    await c.read(playlistProvider.notifier).clear();
    expect(c.read(playlistProvider).value, isNull);
  });

  test('si al arrancar la fuente no se puede abrir, se conserva y se puede reintentar', () async {
    final store = MemorySourceStore(SavedSource.file(m3u));
    File(m3u).deleteSync(); // simula "sin red"/fichero ausente
    final c = _boot(store);
    await expectLater(c.read(playlistProvider.future), throwsA(isA<AppError>()));
    expect(store.value, isNotNull);

    File(m3u).writeAsStringSync('#EXTM3U\n#EXTINF:-1,Vuelve\nhttp://v\n');
    c.invalidate(playlistProvider); // "Reintentar"
    expect((await c.read(playlistProvider.future))!.channels.single.name, 'Vuelve');
  });
}
