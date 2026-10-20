import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/storage/locale_store.dart';
import 'package:lumio/design_system/theme/app_theme.dart';
import 'package:lumio/features/settings/language_switcher.dart';
import 'package:lumio/features/settings/locale_providers.dart';
import 'package:lumio/l10n/app_localizations.dart';
import 'package:lumio/l10n/app_localizations_en.dart';
import 'package:lumio/l10n/app_localizations_es.dart';

Widget _app(MemoryLocaleStore store, {bool extended = true}) => ProviderScope(
      overrides: [localeStoreProvider.overrideWithValue(store)],
      child: Consumer(builder: (context, ref, _) {
        final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('es');
        return MaterialApp(
          theme: AppTheme.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(children: [
              LanguageSwitcher(extended: extended),
              Builder(builder: (c) => Text(AppLocalizations.of(c).navMovies)),
            ]),
          ),
        );
      }),
    );

void main() {
  test('los dos idiomas tienen las mismas claves y ningún texto vacío', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();
    expect((es.navLive, en.navLive), ('En vivo', 'Live'));
    expect((es.commonRetry, en.commonRetry), ('Reintentar', 'Retry'));
    expect(es.seasonsCount(1), '1 temporada');
    expect(en.seasonsCount(3), '3 seasons');
    expect(en.noticeExpiresInDays(1), contains('1 day.'));
  });

  test('el idioma elegido se guarda y se restaura', () async {
    final store = MemoryLocaleStore();
    final c = ProviderContainer(overrides: [localeStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    await c.read(localeProvider.future);
    await c.read(localeProvider.notifier).set('en');
    expect(store.value, 'en');
    expect(c.read(localeProvider).value, const Locale('en'));

    final c2 = ProviderContainer(overrides: [localeStoreProvider.overrideWithValue(store)]);
    addTearDown(c2.dispose);
    expect(await c2.read(localeProvider.future), const Locale('en'));
  });

  test('un idioma no soportado se ignora', () async {
    final store = MemoryLocaleStore('es');
    final c = ProviderContainer(overrides: [localeStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    await c.read(localeProvider.future);
    await c.read(localeProvider.notifier).set('fr');
    expect(store.value, 'es');
    expect(c.read(localeProvider).value, const Locale('es'));
  });

  testWidgets('el selector cambia la app de español a inglés y vuelta', (t) async {
    final store = MemoryLocaleStore('es');
    await t.pumpWidget(_app(store));
    await t.pumpAndSettle();
    expect(find.text('Películas'), findsOneWidget);

    await t.tap(find.text('EN'));
    await t.pumpAndSettle();
    expect(find.text('Movies'), findsOneWidget);
    expect(store.value, 'en');

    await t.tap(find.text('ES'));
    await t.pumpAndSettle();
    expect(find.text('Películas'), findsOneWidget);
  });

  testWidgets('con el menú contraído un solo botón alterna el idioma', (t) async {
    await t.pumpWidget(_app(MemoryLocaleStore('es'), extended: false));
    await t.pumpAndSettle();
    expect(find.text('ES'), findsOneWidget);
    await t.tap(find.text('ES'));
    await t.pumpAndSettle();
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
  });
}
