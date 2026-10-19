import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/models/channel.dart';
import 'package:lumio/core/storage/source_store.dart';
import 'package:lumio/features/home/presentation/recents_page.dart';
import 'package:lumio/features/library/library_providers.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  const source = SavedSource.xtream(host: 'http://srv.example', username: 'ana', password: 'x');
  const a = Channel(index: 0, name: 'ES - LA 1 HD', url: 'http://s/1.ts', stableId: 'x1');
  const b = Channel(index: 1, name: 'ES - LA 2 HD', url: 'http://s/2.ts', stableId: 'x2');

  setUp(() => tmp = Directory.systemTemp.createTempSync('lumio_rec_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // El guardado en disco es E/S real: dentro de un testWidgets hay que usar runAsync.
  Future<ProviderContainer> pump(WidgetTester t) async {
    final c = ProviderContainer(overrides: [
      libraryFileProvider.overrideWithValue(() async => File('${tmp.path}/l.json')),
      channelsByUidProvider.overrideWithValue({'x1': a, 'x2': b}),
    ]);
    addTearDown(c.dispose);
    c.read(activeSourceProvider.notifier).state = source;
    await t.runAsync(() => c.read(libraryProvider.future));
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: RecentsPage())),
    ));
    return c;
  }

  testWidgets('vacío: explica qué es', (t) async {
    await pump(t);
    expect(find.textContaining('Aún no has visto'), findsOneWidget);
    expect(find.text('Borrar'), findsNothing);
  });

  testWidgets('lista el último visto primero y permite borrar', (t) async {
    final c = await pump(t);
    final n = c.read(libraryProvider.notifier);
    await t.runAsync(() async {
      await n.addRecent('x1');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await n.addRecent('x2');
      await n.flush();
    });
    await t.pump();
    final y1 = t.getTopLeft(find.text('LA 1')).dy;
    final y2 = t.getTopLeft(find.text('LA 2')).dy;
    expect(y2, lessThan(y1), reason: 'LA 2 se vio después, sale arriba');

    await t.runAsync(() async {
      await t.tap(find.text('Borrar'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pump();
    expect(find.textContaining('Aún no has visto'), findsOneWidget);
  });
}
