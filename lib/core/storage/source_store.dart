import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../util/stable_hash.dart';

enum SourceType { url, file, xtream }

/// Fuente activa del usuario. Es lo único que se persiste: los canales se
/// vuelven a leer al arrancar.
class SavedSource {
  const SavedSource({
    required this.type,
    required this.location,
    this.username = '',
    this.password = '',
  });

  const SavedSource.url(String url) : this(type: SourceType.url, location: url);
  const SavedSource.file(String path) : this(type: SourceType.file, location: path);
  const SavedSource.xtream({required String host, required String username, required String password})
      : this(type: SourceType.xtream, location: host, username: username, password: password);

  final SourceType type;

  /// URL, ruta de fichero o `http(s)://host:puerto` según [type].
  final String location;
  final String username;
  final String password;

  /// Identificador estable de la fuente: no incluye la contraseña, así que cambiarla no hace
  /// "perder" favoritos ni progreso, y dos dispositivos con la misma cuenta comparten id.
  String get id => stableHash('${type.name}|$location|$username');

  /// Texto seguro para mostrar (nunca incluye contraseñas ni tokens de la URL).
  String get label {
    switch (type) {
      case SourceType.xtream:
        return 'Xtream Codes · ${Uri.tryParse(location)?.host ?? location} ($username)';
      case SourceType.url:
        return 'Lista M3U · ${Uri.tryParse(location)?.host ?? location}';
      case SourceType.file:
        return 'Archivo · ${location.split(RegExp(r'[\\/]')).last}';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'location': location,
        if (username.isNotEmpty) 'username': username,
        if (password.isNotEmpty) 'password': password,
      };

  static SavedSource? fromJson(Object? json) {
    if (json is! Map) return null;
    final type = SourceType.values.where((t) => t.name == json['type']).firstOrNull;
    final location = json['location'];
    if (type == null || location is! String || location.isEmpty) return null;
    return SavedSource(
      type: type,
      location: location,
      username: '${json['username'] ?? ''}',
      password: '${json['password'] ?? ''}',
    );
  }
}

abstract class SourceStore {
  Future<SavedSource?> read();
  Future<void> write(SavedSource source);
  Future<void> clear();

  /// Una fuente "precargada" en la compilación solo se aplica la primera vez; si el
  /// usuario la borra después, no debe reaparecer.
  Future<bool> presetApplied();
  Future<void> markPresetApplied();
}

/// Almacenamiento cifrado por el sistema (DPAPI en Windows, Keychain en
/// macOS/iOS, Keystore en Android, libsecret en Linux).
class SecureSourceStore implements SourceStore {
  SecureSourceStore([FlutterSecureStorage? storage, this._key = 'active_source_v1'])
      : _storage = storage ??
            const FlutterSecureStorage(
              // macOS sin firma de desarrollador: el llavero "Data Protection" (por defecto)
              // exige el entitlement keychain-access-groups y falla con -34018. El llavero
              // clásico funciona sin él. Probado en CI (macOS 15).
              mOptions: MacOsOptions(useDataProtectionKeyChain: false),
            );

  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<SavedSource?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null ? null : SavedSource.fromJson(jsonDecode(raw));
    } catch (_) {
      return null; // dato corrupto o almacén no disponible: empezar sin fuente
    }
  }

  @override
  Future<void> write(SavedSource source) =>
      _storage.write(key: _key, value: jsonEncode(source.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);

  @override
  Future<bool> presetApplied() async {
    try {
      return await _storage.read(key: '${_key}_preset') == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markPresetApplied() => _storage.write(key: '${_key}_preset', value: '1');
}

/// Para tests.
class MemorySourceStore implements SourceStore {
  MemorySourceStore([this.value]);
  SavedSource? value;
  bool _presetApplied = false;

  @override
  Future<bool> presetApplied() async => _presetApplied;
  @override
  Future<void> markPresetApplied() async => _presetApplied = true;

  @override
  Future<SavedSource?> read() async => value;
  @override
  Future<void> write(SavedSource source) async => value = source;
  @override
  Future<void> clear() async => value = null;
}
