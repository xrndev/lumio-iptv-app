import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/l10n/app_localizations.dart';
import 'package:lumio/app.dart';
import 'package:lumio/design_system/theme/app_theme.dart';
import 'package:lumio/features/playlists/presentation/add_source_dialog.dart';
import 'package:lumio/platform_channels/tv_provider.dart';

Widget _dialog({required bool tv}) => ProviderScope(
      overrides: [isTelevisionProvider.overrideWith((ref) async => tv)],
      child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: const Locale('es'),
          theme: AppTheme.dark(),
          home: const Scaffold(body: AddSourceDialog())),
    );

void main() {
  group('añadir fuente según el dispositivo', () {
    testWidgets('en móvil/escritorio ofrece URL, Archivo y Xtream', (t) async {
      await t.pumpWidget(_dialog(tv: false));
      await t.pumpAndSettle();
      expect(find.text('URL M3U'), findsOneWidget);
      expect(find.text('Archivo'), findsOneWidget);
      expect(find.text('Xtream Codes'), findsOneWidget);
    });

    testWidgets('en TV (Fire TV, Android TV) no ofrece Archivo: no hay gestor de archivos', (t) async {
      await t.pumpWidget(_dialog(tv: true));
      await t.pumpAndSettle();
      expect(find.text('URL M3U'), findsOneWidget);
      expect(find.text('Archivo'), findsNothing);
      expect(find.text('Xtream Codes'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('el formulario Xtream funciona con el teclado de pantalla del mando', (t) async {
      await t.pumpWidget(_dialog(tv: true));
      await t.pumpAndSettle();
      await t.tap(find.text('Xtream Codes'));
      await t.pumpAndSettle();
      final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.map((f) => f.textInputAction),
          [TextInputAction.next, TextInputAction.next, TextInputAction.done]);
    });
  });

  group('texto en TV', () {
    test('sube el texto al mínimo de TV', () {
      final s = tvAwareTextScaler(TextScaler.noScaling, tv: true);
      expect(s.scale(10), closeTo(10 * tvTextScale, 1e-9));
    });

    test('respeta una escala del sistema mayor', () {
      final s = tvAwareTextScaler(const TextScaler.linear(1.5), tv: true);
      expect(s.scale(10), closeTo(15, 1e-9));
    });

    test('fuera de TV no cambia nada', () {
      final s = tvAwareTextScaler(TextScaler.noScaling, tv: false);
      expect(s.scale(10), 10);
    });
  });
}
