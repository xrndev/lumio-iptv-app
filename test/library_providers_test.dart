import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/library/library_data.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/library/library_providers.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // AppLifecycleListener lo necesita

  late Directory tmp;
  late File file;
  const source = SavedSource.xtream(host: 'http://srv.example', username: 'ana', password: 'x');

  ProviderContainer boot({SavedSource? active = source}) {
    final c = ProviderContainer(overrides: [
      libraryFileProvider.overrideWithValue(() async => file),
      sourceStoreProvider.overrideWithValue(MemorySourceStore()),
    ]);
    if (active != null) c.read(activeSourceProvider.notifier).state = active;
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lumio_lib_');
    file = File('${tmp.path}/lib/lumio_library.json');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('los favoritos se guardan y sobreviven a un reinicio', () async {
    final a = boot();
    await a.read(libraryProvider.future);
    await a.read(libraryProvider.notifier).toggleFavorite(LibraryKind.channel, 'x42');
    expect(a.read(isFavoriteProvider((kind: LibraryKind.channel, uid: 'x42'))), isTrue);

    final b = boot(); // "reinicio": contenedor nuevo, mismo fichero
    await b.read(libraryProvider.future);
    expect(b.read(isFavoriteProvider((kind: LibraryKind.channel, uid: 'x42'))), isTrue);
    expect(b.read(isFavoriteProvider((kind: LibraryKind.channel, uid: 'otro'))), isFalse);
  });

  test('cada fuente tiene su propia biblioteca', () async {
    final a = boot();
    await a.read(libraryProvider.future);
    await a.read(libraryProvider.notifier).toggleFavorite(LibraryKind.channel, 'x1');

    a.read(activeSourceProvider.notifier).state =
        const SavedSource.xtream(host: 'http://otro.example', username: 'bea', password: 'y');
    expect(a.read(isFavoriteProvider((kind: LibraryKind.channel, uid: 'x1'))), isFalse);

    a.read(activeSourceProvider.notifier).state = source;
    expect(a.read(isFavoriteProvider((kind: LibraryKind.channel, uid: 'x1'))), isTrue);
  });

  test('cambiar la contraseña no hace perder los favoritos', () async {
    final a = boot();
    await a.read(libraryProvider.future);
    await a.read(libraryProvider.notifier).toggleFavorite(LibraryKind.movie, 'm1');
    a.read(activeSourceProvider.notifier).state =
        const SavedSource.xtream(host: 'http://srv.example', username: 'ana', password: 'NUEVA');
    expect(a.read(isFavoriteProvider((kind: LibraryKind.movie, uid: 'm1'))), isTrue);
  });

  test('recientes y progreso se guardan al volcar (flush)', () async {
    final a = boot();
    await a.read(libraryProvider.future);
    final n = a.read(libraryProvider.notifier);
    await n.addRecent('x7');
    await n.saveProgress(const ProgressEntry(
        key: 'm5', isEpisode: false, id: 5, ext: 'mkv', title: 'Peli', posMs: 600000, durMs: 6000000, t: 1));
    await n.flush();

    final b = boot();
    await b.read(libraryProvider.future);
    final lib = b.read(currentLibraryProvider);
    expect(lib.recentUids(), ['x7']);
    expect(lib.progressOf('m5')!.resumeAt, const Duration(minutes: 10));
  });

  test('un fichero corrupto no impide arrancar y se aparta', () async {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('{esto no es json');
    final a = boot();
    await a.read(libraryProvider.future);
    expect(a.read(currentLibraryProvider).favoriteUids(LibraryKind.channel), isEmpty);
    expect(File('${file.path}.corrupt').existsSync(), isTrue);
  });

  group('código para pasar favoritos a otro dispositivo', () {
    test('exportar en un dispositivo e importar en otro (misma cuenta)', () async {
      final phone = boot();
      await phone.read(libraryProvider.future);
      await phone.read(libraryProvider.notifier).toggleFavorite(LibraryKind.channel, 'x1');
      await phone.read(libraryProvider.notifier).toggleFavorite(LibraryKind.series, 's9');
      final code = await phone.read(libraryProvider.notifier).exportCode();

      file = File('${tmp.path}/otro_dispositivo.json'); // otro "teléfono"
      final tv = boot();
      await tv.read(libraryProvider.future);
      await tv.read(libraryProvider.notifier).toggleFavorite(LibraryKind.channel, 'x2');
      expect(await tv.read(libraryProvider.notifier).importCode(code), ImportResult.merged);

      final lib = tv.read(currentLibraryProvider);
      expect(lib.favoriteUids(LibraryKind.channel).toSet(), {'x1', 'x2'});
      expect(lib.favoriteUids(LibraryKind.series), ['s9']);
    });

    test('rechaza un código de otra cuenta y uno inválido', () async {
      final a = boot();
      await a.read(libraryProvider.future);
      final code = encodeShareCode('cuenta-ajena', SourceLibrary.empty);
      expect(await a.read(libraryProvider.notifier).importCode(code), ImportResult.otherSource);
      expect(await a.read(libraryProvider.notifier).importCode('basura'), ImportResult.invalidCode);
    });
  });
}
