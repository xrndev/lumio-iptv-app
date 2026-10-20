// Herramienta (no es una prueba de CI): capturas para la ficha de Google Play, con canales
// y películas FICTICIOS (nada de marcas ni logos de terceros).
//
//   flutter test integration_test/store_shots_test.dart -d windows
//   (LUMIO_SHOTS_LOCALE=en para inglés; LUMIO_SHOTS_DIR para la carpeta de salida)
//
// Deja phone_N.png (1080x1920) y wide_N.png (1920x1080).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumio/app.dart';
import 'package:lumio/core/library/library_data.dart';
import 'package:lumio/core/models/media.dart';
import 'package:lumio/core/network/xtream_client.dart';
import 'package:lumio/core/storage/locale_store.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/library/library_providers.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';
import 'package:lumio/features/settings/locale_providers.dart';
import 'package:lumio/features/vod/vod_providers.dart';
import 'package:media_kit/media_kit.dart';

const _m3u = '''#EXTM3U
#EXTINF:-1 group-title="General",Canal Aurora HD
http://127.0.0.1:9/1.ts
#EXTINF:-1 group-title="General",Noticias 24 Horas
http://127.0.0.1:9/2.ts
#EXTINF:-1 group-title="General",Plaza Mayor TV
http://127.0.0.1:9/3.ts
#EXTINF:-1 group-title="General",Telemar
http://127.0.0.1:9/4.ts
#EXTINF:-1 group-title="Sports",Deportes Plus 4K
http://127.0.0.1:9/5.ts
#EXTINF:-1 group-title="Sports",Liga Total
http://127.0.0.1:9/6.ts
#EXTINF:-1 group-title="Cinema",Cine Estelar FHD
http://127.0.0.1:9/7.ts
#EXTINF:-1 group-title="Cinema",Estrenos Club
http://127.0.0.1:9/8.ts
#EXTINF:-1 group-title="Nature",Naturaleza HD
http://127.0.0.1:9/9.ts
#EXTINF:-1 group-title="Nature",Planeta Azul
http://127.0.0.1:9/10.ts
#EXTINF:-1 group-title="Kids",Pequeños Genios
http://127.0.0.1:9/11.ts
#EXTINF:-1 group-title="Music",Ritmo Radio TV
http://127.0.0.1:9/12.ts
''';

MediaCatalog _movies() {
  const titles = [
    'La tormenta', 'Noche en la ciudad', 'El último viaje', 'Horizonte rojo', 'Cartas a Marte',
    'La isla del tesoro', 'Sombras', 'El faro', 'Cruce de caminos', 'Verano del 98', 'Marea alta',
    'La casa del lago', 'Fuego cruzado', 'Eco', 'Brújula', 'Ciudad de papel',
  ];
  return MediaCatalog(
    groups: const ['Drama', 'Aventura'],
    items: [
      for (var i = 0; i < titles.length; i++)
        VodItem(
          id: i,
          title: titles[i],
          poster: '',
          group: i.isEven ? 'Drama' : 'Aventura',
          ext: 'mp4',
          rating: 5.5 + (i % 5) * 0.8,
          year: '${2019 + i % 7}',
        ),
    ],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  testWidgets('capturas para Google Play', (t) async {
    final lang = Platform.environment['LUMIO_SHOTS_LOCALE'] ?? 'es';
    final dir = Directory(
        Platform.environment['LUMIO_SHOTS_DIR'] ?? '${Directory.systemTemp.path}/lumio_store_shots/$lang')
      ..createSync(recursive: true);
    final tmp = Directory.systemTemp.createTempSync('lumio_store_src_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final list = File('${tmp.path}/lista.m3u')..writeAsStringSync(_m3u);

    final container = ProviderContainer(overrides: [
      sourceStoreProvider.overrideWithValue(MemorySourceStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(lang)),
      libraryFileProvider.overrideWithValue(() async => File('${tmp.path}/biblioteca.json')),
      xtreamCredentialsProvider
          .overrideWith((ref) => XtreamCredentials(host: 'srv.example', username: 'u', password: 'p')),
      mediaCatalogProvider.overrideWith((ref, kind) async => _movies()),
    ]);
    addTearDown(container.dispose);

    final key = GlobalKey();
    Future<void> shot(String name, {required double scale}) async {
      await t.pumpAndSettle(const Duration(milliseconds: 800));
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: scale);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('${dir.path}/$name.png').writeAsBytesSync(bytes!);
    }

    // Vista vertical de teléfono: 540x960 dp → 1080x1920 px.
    t.view
      ..physicalSize = const Size(540, 960)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: UncontrolledProviderScope(container: container, child: const IptvApp()),
    ));
    await t.pumpAndSettle(const Duration(seconds: 1));
    await container.read(playlistProvider.notifier).loadFile(list.path);
    await t.pumpAndSettle(const Duration(seconds: 1));
    container.read(xtreamCredentialsProvider.notifier).state =
        XtreamCredentials(host: 'srv.example', username: 'u', password: 'p');

    final channels = container.read(channelsByUidProvider);
    String uidOf(String name) => channels.values.firstWhere((c) => c.name.contains(name)).uid;
    await t.runAsync(() async {
      final lib = container.read(libraryProvider.notifier);
      await container.read(libraryProvider.future);
      await lib.toggleFavorite(LibraryKind.channel, uidOf('Aurora'));
      await lib.toggleFavorite(LibraryKind.channel, uidOf('Deportes Plus'));
      await lib.toggleFavorite(LibraryKind.channel, uidOf('Naturaleza'));
      for (final n in ['Planeta Azul', 'Cine Estelar', 'Noticias']) {
        await lib.addRecent(uidOf(n));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await t.pump();

    final english = lang == 'en';
    String tr(String es, String en) => english ? en : es;

    await shot('phone_1_live', scale: 2);
    await t.tap(find.text(tr('Películas', 'Movies')).last);
    await shot('phone_2_movies', scale: 2);
    await t.tap(find.text(tr('Favoritos', 'Favorites')).last);
    await shot('phone_3_favorites', scale: 2);
    await t.tap(find.text(tr('Recientes', 'Recents')).last);
    await shot('phone_4_recents', scale: 2);

    // Horizontal (tablet / TV): 960x540 dp → 1920x1080 px.
    t.view.physicalSize = const Size(960, 540);
    await t.tap(find.text(tr('En vivo', 'Live')).last);
    await shot('wide_1_live', scale: 2);
    await t.tap(find.text(tr('Películas', 'Movies')).last);
    await shot('wide_2_movies', scale: 2);
  });
}
