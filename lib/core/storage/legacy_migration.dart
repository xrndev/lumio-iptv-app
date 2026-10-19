import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// En Windows, Flutter guarda el almacén cifrado en `%APPDATA%\<Empresa>\<Producto>`, con
/// los valores de `windows/runner/Runner.rc`. Al pasar de "IPTV Launcher"
/// (`com.iptvlauncher\iptv_launcher`) a Lumio (`Lumio\Lumio`) esa carpeta cambió y la fuente
/// guardada parecía perdida. Esta migración la copia una sola vez; no pisa datos nuevos.
///
/// El fichero está cifrado con DPAPI (ligado al usuario de Windows, no a la ruta), así que
/// copiarlo es válido. Devuelve `true` si copió algo. Nunca lanza: no debe impedir arrancar.
Future<bool> migrateLegacyWindowsData({String? legacyFile, String? targetFile}) async {
  try {
    final legacy = File(legacyFile ?? _defaultLegacyFile());
    final target = File(targetFile ?? await _defaultTargetFile());
    if (!await legacy.exists() || await target.exists()) return false;
    await target.parent.create(recursive: true);
    await legacy.copy(target.path); // se conserva el original por seguridad
    return true;
  } catch (e) {
    debugPrint('No se pudo migrar la fuente guardada de la versión anterior: $e');
    return false;
  }
}

String _defaultLegacyFile() {
  final appData = Platform.environment['APPDATA'] ?? '';
  return '$appData\\com.iptvlauncher\\iptv_launcher\\flutter_secure_storage.dat';
}

Future<String> _defaultTargetFile() async {
  final dir = await getApplicationSupportDirectory();
  return '${dir.path}${Platform.pathSeparator}flutter_secure_storage.dat';
}
