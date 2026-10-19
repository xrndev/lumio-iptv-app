import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/storage/legacy_migration.dart';

void main() {
  late Directory tmp;
  late File legacy;
  late File target;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lumio_migr_');
    legacy = File('${tmp.path}/old/iptv_launcher/flutter_secure_storage.dat')
      ..createSync(recursive: true)
      ..writeAsStringSync('datos-cifrados-antiguos');
    target = File('${tmp.path}/new/Lumio/flutter_secure_storage.dat');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('copia la fuente guardada de la carpeta antigua a la nueva', () async {
    expect(await migrateLegacyWindowsData(legacyFile: legacy.path, targetFile: target.path), isTrue);
    expect(target.readAsStringSync(), 'datos-cifrados-antiguos');
    expect(legacy.existsSync(), isTrue, reason: 'se conserva el original');
  });

  test('no pisa datos que ya existen en la carpeta nueva', () async {
    target
      ..createSync(recursive: true)
      ..writeAsStringSync('datos-nuevos');
    expect(await migrateLegacyWindowsData(legacyFile: legacy.path, targetFile: target.path), isFalse);
    expect(target.readAsStringSync(), 'datos-nuevos');
  });

  test('sin datos antiguos no hace nada y no falla', () async {
    legacy.deleteSync();
    expect(await migrateLegacyWindowsData(legacyFile: legacy.path, targetFile: target.path), isFalse);
    expect(target.existsSync(), isFalse);
  });

  test('es idempotente: ejecutarla dos veces no cambia nada', () async {
    await migrateLegacyWindowsData(legacyFile: legacy.path, targetFile: target.path);
    expect(await migrateLegacyWindowsData(legacyFile: legacy.path, targetFile: target.path), isFalse);
  });
}
