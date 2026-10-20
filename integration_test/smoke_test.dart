// Prueba de humo multiplataforma: arranca la app real (con libmpv), navega por el menú,
// comprueba el foco con teclado/mando, carga una lista y abre el reproductor.
//
//   flutter test integration_test/smoke_test.dart -d <windows|linux|macos|id-de-simulador>
//
// No usa red: la lista es local y el stream apunta a un puerto cerrado, de modo que se
// ejercita también la ruta de error/recuperación del reproductor.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumio/app.dart';
import 'package:lumio/core/storage/locale_store.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';
import 'package:lumio/features/settings/locale_providers.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // carga libmpv: aquí fallaría una plataforma sin librerías

  testWidgets('arranque, navegación, foco con mando y reproductor', (t) async {
    final tmp = Directory.systemTemp.createTempSync('iptv_smoke_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final m3u = File('${tmp.path}/lista.m3u')
      ..writeAsStringSync('#EXTM3U\n'
          '#EXTINF:-1 group-title="Prueba",Canal Alfa\nhttp://127.0.0.1:9/alfa.ts\n'
          '#EXTINF:-1 group-title="Prueba",Canal Beta\nhttp://127.0.0.1:9/beta.ts\n');

    final container = ProviderContainer(
      overrides: [
        sourceStoreProvider.overrideWithValue(MemorySourceStore()),
        localeStoreProvider.overrideWithValue(MemoryLocaleStore('es')),
      ],
    );
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(container: container, child: const IptvApp()));
    await t.pumpAndSettle(const Duration(seconds: 1));

    // 1. Arranque sin fuente
    expect(find.text('Añadir fuente'), findsWidgets);

    // 2. Navegación por el menú
    for (final (label, expected) in [
      ('Películas', 'requiere una cuenta Xtream'),
      ('Buscar', 'Escribe al menos 2 letras'),
      ('Ajustes', 'FUENTE'),
    ]) {
      await t.tap(find.text(label).last);
      await t.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.textContaining(expected), findsWidgets, reason: 'pantalla "$label"');
    }
    await t.tap(find.text('En vivo').last);
    await t.pumpAndSettle(const Duration(milliseconds: 600));

    // 3. Foco con teclado / mando: las flechas deben mover el foco
    final before = FocusManager.instance.primaryFocus;
    var moved = false;
    for (final key in [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowRight]) {
      await t.sendKeyEvent(key);
      await t.pump(const Duration(milliseconds: 200));
      if (FocusManager.instance.primaryFocus != before) moved = true;
    }
    expect(moved, isTrue, reason: 'las flechas no mueven el foco (¿sin navegación por mando?)');

    // 4. Cargar una lista local
    await container.read(playlistProvider.notifier).loadFile(m3u.path);
    await t.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Canal Alfa'), findsOneWidget);
    expect(find.text('Canal Beta'), findsOneWidget);

    // 5. Abrir el reproductor: inicializa libmpv y, al no haber servidor, debe terminar
    //    mostrando el error con "Reintentar" (no colgarse ni lanzar excepciones).
    await t.tap(find.text('Canal Alfa'));
    var shown = false;
    for (var i = 0; i < 60 && !shown; i++) {
      await t.pump(const Duration(milliseconds: 250));
      shown = find.text('Reintentar').evaluate().isNotEmpty;
    }
    expect(shown, isTrue, reason: 'el reproductor no mostró el error de apertura en 15 s');
    expect(t.takeException(), isNull);
  });
}
