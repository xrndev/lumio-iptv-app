import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/l10n/app_localizations.dart';
import 'package:lumio/core/models/channel.dart';
import 'package:lumio/core/models/media.dart';
import 'package:lumio/core/network/xtream_client.dart';
import 'package:lumio/design_system/theme/app_theme.dart';
import 'package:lumio/design_system/widgets/wheel_scroll_row.dart';
import 'package:lumio/features/home/presentation/search_page.dart';
import 'package:lumio/features/playlists/playlist_providers.dart';
import 'package:lumio/features/vod/presentation/media_page.dart';
import 'package:lumio/features/vod/vod_providers.dart';

final _creds = XtreamCredentials(host: 'srv.example', username: 'u', password: 'p');

final _movies = MediaCatalog(
  groups: const ['VOD | SPANISH', 'VOD | NEW'],
  items: [
    for (var i = 0; i < 60; i++)
      VodItem(
        id: i,
        title: 'ES - Película $i - 2026 (SUB)',
        poster: 'http://img.example/$i.jpg',
        group: i.isEven ? 'VOD | SPANISH' : 'VOD | NEW',
        ext: 'mp4',
        rating: 7.5,
        year: '2026',
      ),
  ],
);

const _series = MediaCatalog(
  groups: ['SRS | SPANISH'],
  items: [
    SeriesItem(id: 1, title: 'ES - Serie Uno', poster: '', group: 'SRS | SPANISH', year: '2025'),
  ],
);

List<Override> _overrides() => [
      xtreamCredentialsProvider.overrideWith((ref) => _creds),
      mediaCatalogProvider.overrideWith(
          (ref, kind) async => kind == MediaKind.movies ? _movies : _series),
      vodDetailProvider.overrideWith((ref, id) async =>
          const VodDetail(plot: 'Una sinopsis larga.', duration: '01:41:00', genre: 'Drama')),
      seriesDetailProvider.overrideWith((ref, id) async => const SeriesDetail(seasons: {
            1: [
              Episode(id: 10, season: 1, number: 1, title: 'Serie - S01E01 - Piloto', ext: 'mp4'),
              Episode(id: 11, season: 1, number: 2, title: 'Serie - S01E02 - Dos', ext: 'mp4'),
            ],
            2: [Episode(id: 20, season: 2, number: 1, title: 'Serie - S02E01 - Vuelta', ext: 'mp4')],
          })),
    ];

Widget _app(Widget home, {List<Override>? overrides}) => ProviderScope(
      overrides: overrides ?? _overrides(),
      child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: const Locale('es'),
          theme: AppTheme.dark(),
          home: Scaffold(body: home)),
    );

void _size(WidgetTester t, double w, double h) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  for (final w in [400.0, 900.0, 1600.0]) {
    testWidgets('rejilla de películas sin overflow a ${w.toInt()} dp y abre la ficha', (t) async {
      _size(t, w, 900);
      await t.pumpWidget(_app(const MediaPage(kind: MediaKind.movies)));
      await t.pumpAndSettle();

      expect(find.text('Películas'), findsOneWidget);
      expect(find.byType(PosterCard), findsWidgets);
      expect(find.text('Película 0'), findsWidgets); // título limpio, sin "ES -" ni año

      await t.tap(find.byType(PosterCard).first);
      await t.pumpAndSettle();
      expect(find.text('Reproducir'), findsOneWidget);
      expect(find.text('Una sinopsis larga.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('series: ficha con temporadas y episodios', (t) async {
    _size(t, 1200, 900);
    await t.pumpWidget(_app(const MediaPage(kind: MediaKind.series)));
    await t.pumpAndSettle();
    await t.tap(find.byType(PosterCard).first);
    await t.pumpAndSettle();

    expect(find.text('Temporada 1'), findsOneWidget);
    expect(find.text('Piloto'), findsOneWidget);
    await t.tap(find.text('Temporada 2'));
    await t.pumpAndSettle();
    expect(find.text('Vuelta'), findsOneWidget);
    expect(find.text('Piloto'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('sin cuenta Xtream se explica y ofrece añadirla', (t) async {
    _size(t, 1200, 900);
    await t.pumpWidget(_app(const MediaPage(kind: MediaKind.movies),
        overrides: [xtreamCredentialsProvider.overrideWith((ref) => null)]));
    await t.pumpAndSettle();
    expect(find.textContaining('requiere una cuenta Xtream'), findsOneWidget);
    expect(find.text('Añadir cuenta Xtream'), findsOneWidget);
  });

  testWidgets('búsqueda global muestra canales, películas y series', (t) async {
    _size(t, 1200, 900);
    final overrides = [
      ..._overrides(),
      playlistProvider.overrideWith(() => _FakePlaylist()),
    ];
    await t.pumpWidget(_app(const SearchPage(), overrides: overrides));
    await t.pumpAndSettle();
    expect(find.text('Escribe al menos 2 letras'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'uno');
    await t.pumpAndSettle();
    expect(find.text('Canales'), findsOneWidget);
    expect(find.text('Canal Uno'), findsOneWidget);
    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Películas'), findsNothing); // ninguna película contiene "uno"

    await t.enterText(find.byType(TextField), 'Película 1');
    await t.pumpAndSettle();
    expect(find.text('Películas'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('la rueda del ratón desplaza la fila de chips', (t) async {
    _size(t, 500, 300);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WheelScrollRow(children: [
          for (var i = 0; i < 30; i++) CategoryChip(label: 'Categoría número $i', selected: false, onTap: () {}),
        ]),
      ),
    ));
    final state = t.state<ScrollableState>(find.byType(Scrollable));
    expect(state.position.pixels, 0);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await t.sendEventToBinding(pointer.hover(const Offset(250, 22)));
    await t.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await t.pump();
    expect(state.position.pixels, 120);

    await t.sendEventToBinding(pointer.scroll(const Offset(0, -500)));
    await t.pump();
    expect(state.position.pixels, 0);
  });

  testWidgets('arrastrar con el ratón también desplaza', (t) async {
    _size(t, 500, 300);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WheelScrollRow(children: [
          for (var i = 0; i < 30; i++) CategoryChip(label: 'Categoría número $i', selected: false, onTap: () {}),
        ]),
      ),
    ));
    final state = t.state<ScrollableState>(find.byType(Scrollable));
    final g = await t.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: const Offset(300, 22));
    await g.down(const Offset(300, 22));
    await g.moveBy(const Offset(-60, 0));
    await g.moveBy(const Offset(-60, 0));
    await g.moveBy(const Offset(-80, 0));
    await t.pump();
    expect(state.position.pixels, greaterThan(0));
    await g.up();
  });
}

class _FakePlaylist extends PlaylistController {
  @override
  Future<M3uPlaylist?> build() async => const M3uPlaylist(channels: [
        Channel(index: 0, name: 'Canal Uno', url: 'http://x/1', group: 'G'),
        Channel(index: 1, name: 'Canal Dos', url: 'http://x/2', group: 'G'),
      ]);
}
