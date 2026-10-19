// Herramienta (no es una prueba de CI): renderiza pantallas de la app a PNG con el motor real,
// sin depender de capturar la ventana del sistema.
//
//   flutter test integration_test/screenshots_test.dart -d windows
//
// Deja los PNG en %TEMP%/lumio_shots (o en $LUMIO_SHOTS_DIR).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumio/app.dart';
import 'package:lumio/core/models/media.dart';
import 'package:lumio/core/network/xtream_client.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';
import 'package:lumio/features/vod/vod_providers.dart';
import 'package:media_kit/media_kit.dart';

const _m3u = '''#EXTM3U
#EXTINF:-1 group-title="Generalistas",La 1 HD
http://127.0.0.1:9/1.ts
#EXTINF:-1 group-title="Generalistas",La 2
http://127.0.0.1:9/2.ts
#EXTINF:-1 group-title="Generalistas",Antena 3
http://127.0.0.1:9/3.ts
#EXTINF:-1 group-title="Generalistas",Cuatro
http://127.0.0.1:9/4.ts
#EXTINF:-1 group-title="Generalistas",Telecinco
http://127.0.0.1:9/5.ts
#EXTINF:-1 group-title="Generalistas",La Sexta
http://127.0.0.1:9/6.ts
#EXTINF:-1 group-title="Deportes",Movistar LaLiga 4K
http://127.0.0.1:9/7.ts
#EXTINF:-1 group-title="Deportes",DAZN 1
http://127.0.0.1:9/8.ts
#EXTINF:-1 group-title="Cine",Movistar Estrenos
http://127.0.0.1:9/9.ts
#EXTINF:-1 group-title="Cine",AXN Movies
http://127.0.0.1:9/10.ts
#EXTINF:-1 group-title="Documentales",National Geographic
http://127.0.0.1:9/11.ts
#EXTINF:-1 group-title="Documentales",Discovery Channel
http://127.0.0.1:9/12.ts
''';

MediaCatalog _movies() {
  const titles = [
    'La tormenta', 'Tenzing', 'Noche en la ciudad', 'El último viaje', 'Horizonte rojo',
    'Cartas a Marte', 'La isla del tesoro', 'Sombras', 'Origen', 'El faro', 'Cruce de caminos',
    'Verano del 98', 'Marea alta', 'La casa del lago', 'Fuego cruzado', 'Eco',
  ];
  return MediaCatalog(
    groups: const ['VOD | SPANISH', 'VOD | ESTRENOS'],
    items: [
      for (var i = 0; i < titles.length; i++)
        VodItem(
          id: i,
          title: titles[i],
          poster: '',
          group: i.isEven ? 'VOD | SPANISH' : 'VOD | ESTRENOS',
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

  testWidgets('capturas de pantalla', (t) async {
    final dir = Directory(Platform.environment['LUMIO_SHOTS_DIR'] ?? '${Directory.systemTemp.path}/lumio_shots')
      ..createSync(recursive: true);
    final tmp = Directory.systemTemp.createTempSync('lumio_shots_src_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final list = File('${tmp.path}/lista.m3u')..writeAsStringSync(_m3u);

    final container = ProviderContainer(overrides: [
      sourceStoreProvider.overrideWithValue(MemorySourceStore()),
      xtreamCredentialsProvider.overrideWith((ref) => XtreamCredentials(host: 'srv.example', username: 'u', password: 'p')),
      mediaCatalogProvider.overrideWith((ref, kind) async => kind == MediaKind.movies ? _movies() : _movies()),
    ]);
    addTearDown(container.dispose);

    final key = GlobalKey();
    Future<void> shot(String name) async {
      await t.pumpAndSettle(const Duration(milliseconds: 800));
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('${dir.path}/$name.png').writeAsBytesSync(bytes!);
    }

    t.view
      ..physicalSize = const Size(1500, 880)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: UncontrolledProviderScope(container: container, child: const IptvApp()),
    ));
    await t.pumpAndSettle(const Duration(seconds: 1));

    await container.read(playlistProvider.notifier).loadFile(list.path);
    await t.pumpAndSettle(const Duration(seconds: 1));
    // loadFile reinicia las credenciales de Xtream: se vuelven a poner para las pantallas de VOD.
    container.read(xtreamCredentialsProvider.notifier).state =
        XtreamCredentials(host: 'srv.example', username: 'u', password: 'p');
    await shot('1_en_vivo');

    await t.tap(find.text('Películas').last);
    await shot('2_peliculas');

    await t.tap(find.text('Buscar').last);
    await t.enterText(find.byType(TextField), 'la ');
    await shot('3_buscar');

    await t.tap(find.text('Ajustes').last);
    await shot('4_ajustes');

    // Móvil vertical (barra inferior flotante).
    t.view.physicalSize = const Size(430, 900);
    await t.tap(find.text('En vivo').last);
    await shot('5_movil_en_vivo');
  });
}
