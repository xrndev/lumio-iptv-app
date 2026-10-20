import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Guarda el idioma elegido por el usuario (código de idioma, p. ej. `es` o `en`).
/// Sin valor guardado se sigue el idioma del sistema.
abstract class LocaleStore {
  Future<String?> read();
  Future<void> write(String code);
}

class FileLocaleStore implements LocaleStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}lumio_locale.txt');
  }

  @override
  Future<String?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final v = (await f.readAsString()).trim();
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String code) async {
    try {
      await (await _file()).writeAsString(code, flush: true);
    } catch (_) {
      // El idioma es una comodidad: si no se puede guardar, vale para esta sesión.
    }
  }
}

class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String code) async => value = code;
}
