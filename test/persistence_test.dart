import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_launcher/core/storage/source_store.dart';
import 'package:iptv_launcher/features/playlists/playlist_providers.dart';

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

  test('si al arrancar la fuente no se puede abrir, se conserva y se puede reintentar', () async {
    final store = MemorySourceStore(SavedSource.file(m3u));
    File(m3u).deleteSync(); // simula "sin red"/fichero ausente
    final c = _boot(store);
    await expectLater(c.read(playlistProvider.future), throwsA(isA<FileSystemException>()));
    expect(store.value, isNotNull);

    File(m3u).writeAsStringSync('#EXTM3U\n#EXTINF:-1,Vuelve\nhttp://v\n');
    c.invalidate(playlistProvider); // "Reintentar"
    expect((await c.read(playlistProvider.future))!.channels.single.name, 'Vuelve');
  });
}
