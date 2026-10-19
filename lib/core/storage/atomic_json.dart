import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Lee un JSON; `null` si no existe. Si está corrupto lo aparta como `.corrupt` (para no
/// perderlo en silencio ni quedar atascados) y devuelve `null`.
Future<Object?> readJsonFile(File file) async {
  try {
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString());
  } catch (e) {
    debugPrint('JSON ilegible en ${file.path}: $e');
    try {
      await file.rename('${file.path}.corrupt');
    } catch (_) {}
    return null;
  }
}

/// Escribe un JSON de forma atómica: primero a un temporal y luego se renombra, de modo que un
/// corte de luz o un cierre forzado nunca deja el fichero a medias.
Future<void> writeJsonAtomic(File file, Object? json) async {
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString(jsonEncode(json), flush: true);
  await tmp.rename(file.path);
}

/// Igual que [readJsonFile] pero para ficheros comprimidos con gzip (cachés grandes).
Future<Object?> readJsonGzip(File file) async {
  try {
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return jsonDecode(utf8.decode(gzip.decode(bytes)));
  } catch (e) {
    debugPrint('Caché ilegible en ${file.path}: $e');
    try {
      await file.delete();
    } catch (_) {}
    return null;
  }
}

Future<void> writeJsonGzip(File file, Object? json) async {
  await file.parent.create(recursive: true);
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsBytes(gzip.encode(utf8.encode(jsonEncode(json))), flush: true);
  await tmp.rename(file.path);
}
