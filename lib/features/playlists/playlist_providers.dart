import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/channel.dart';
import '../../core/network/playlist_downloader.dart';
import '../../core/network/xtream_client.dart';
import '../../core/parsing/m3u_parser.dart';
import '../../core/storage/source_store.dart';

final playlistDownloaderProvider = Provider((ref) => PlaylistDownloader());
final xtreamClientProvider = Provider((ref) => XtreamClient());

/// Datos de la cuenta Xtream activa (estado y caducidad), si la fuente es Xtream.
final xtreamAccountProvider = StateProvider<XtreamAccount?>((ref) => null);

/// Credenciales de la cuenta Xtream activa (necesarias para VOD y series).
final xtreamCredentialsProvider = StateProvider<XtreamCredentials?>((ref) => null);

/// Almacén persistente de la fuente activa (cifrado por el sistema).
final sourceStoreProvider = Provider<SourceStore>((ref) {
  // Solo debug: IPTV_NO_PERSIST=1 evita tocar la fuente guardada del usuario en pruebas.
  if (kDebugMode && Platform.environment['IPTV_NO_PERSIST'] == '1') return MemorySourceStore();
  return SecureSourceStore();
});

/// Fuente precargada en la compilación; vacía en las builds normales.
final buildPresetProvider = Provider<String>((ref) => const String.fromEnvironment('IPTV_PRESET'));

/// Fuente activa guardada (para mostrarla en Ajustes). `null` = ninguna.
final activeSourceProvider = StateProvider<SavedSource?>((ref) => null);

/// Resultado de abrir una fuente, con los datos extra que solo aplican a Xtream.
class _Opened {
  const _Opened(this.playlist, {this.account, this.creds});
  final M3uPlaylist playlist;
  final XtreamAccount? account;
  final XtreamCredentials? creds;
}

/// Playlist activa. `null` = no hay ninguna fuente.
///
/// La fuente se guarda al cargarla con éxito y se restaura sola al arrancar;
/// solo desaparece con [clear] (acción manual del usuario).
class PlaylistController extends AsyncNotifier<M3uPlaylist?> {
  @override
  Future<M3uPlaylist?> build() async {
    final store = ref.read(sourceStoreProvider);
    final saved = await store.read() ?? await _presetSource(store);
    if (saved == null) return null;
    final opened = await _open(saved); // si falla (sin red) el estado es error y la fuente se conserva
    // No se pueden modificar otros providers durante build().
    unawaited(Future.microtask(() => _apply(saved, opened)));
    return opened.playlist;
  }

  /// Cuenta Xtream precargada en la compilación:
  /// `--dart-define=IPTV_PRESET=<base64 de "host|usuario|clave">` (base64 para no
  /// depender del entrecomillado del shell). Vacía por defecto: solo para builds de
  /// prueba hechas a medida. Se aplica una vez.
  Future<SavedSource?> _presetSource(SourceStore store) async {
    final raw = ref.read(buildPresetProvider);
    if (raw.isEmpty || await store.presetApplied()) return null;
    final String decoded;
    try {
      decoded = utf8.decode(base64.decode(raw));
    } on FormatException {
      return null;
    }
    final parts = decoded.split('|');
    if (parts.length != 3 || parts.any((p) => p.isEmpty)) return null;
    final source = SavedSource.xtream(host: parts[0], username: parts[1], password: parts[2]);
    await _persist(store, source);
    try {
      await store.markPresetApplied();
    } catch (e) {
      debugPrint('No se pudo registrar la precarga: $e');
    }
    return source;
  }

  /// Guardar es un extra: si el almacén seguro de la plataforma falla (llavero sin
  /// permisos, sin servicio de secretos…) la fuente debe usarse igualmente.
  Future<void> _persist(SourceStore store, SavedSource source) async {
    try {
      await store.write(source);
    } catch (e) {
      debugPrint('No se pudo guardar la fuente (se usará solo en esta sesión): $e');
    }
  }

  Future<_Opened> _open(SavedSource s) async {
    switch (s.type) {
      case SourceType.url:
        final file = await ref.read(playlistDownloaderProvider).download(s.location);
        return _Opened(await M3uParser.parseFile(file.path));
      case SourceType.file:
        if (!await File(s.location).exists()) {
          throw FileSystemException('El archivo ya no existe', s.location);
        }
        return _Opened(await M3uParser.parseFile(s.location));
      case SourceType.xtream:
        final creds =
            XtreamCredentials(host: s.location, username: s.username, password: s.password);
        final r = await ref.read(xtreamClientProvider).loadLive(creds);
        return _Opened(r.playlist, account: r.account, creds: creds);
    }
  }

  void _apply(SavedSource source, _Opened o) {
    if (kDebugMode) {
      File('${Directory.systemTemp.path}/iptv_source.log').writeAsStringSync(
          '[${DateTime.now().toIso8601String()}] fuente activa: ${source.label} '
          '(${o.playlist.channels.length} canales)\n',
          mode: FileMode.append);
    }
    ref.read(activeSourceProvider.notifier).state = source;
    ref.read(xtreamAccountProvider.notifier).state = o.account;
    ref.read(xtreamCredentialsProvider.notifier).state = o.creds;
  }

  void _reset() {
    ref.read(xtreamAccountProvider.notifier).state = null;
    ref.read(xtreamCredentialsProvider.notifier).state = null;
    ref.read(selectedGroupProvider.notifier).state = null;
    ref.read(channelSearchProvider.notifier).state = '';
  }

  /// Abre [source] y, solo si funciona, la guarda (una fuente nueva que falla no
  /// borra la anterior).
  Future<void> _activate(SavedSource source) async {
    _reset();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final opened = await _open(source);
      await _persist(ref.read(sourceStoreProvider), source);
      _apply(source, opened);
      return opened.playlist;
    });
  }

  Future<void> loadUrl(String url) => _activate(SavedSource.url(url));
  Future<void> loadFile(String path) => _activate(SavedSource.file(path));
  Future<void> loadXtream(XtreamCredentials c) => _activate(
      SavedSource.xtream(host: c.host, username: c.username, password: c.password));

  /// Elimina la fuente guardada y vuelve al estado inicial. Solo la llama el usuario.
  Future<void> clear() async {
    try {
      await ref.read(sourceStoreProvider).clear();
    } catch (e) {
      debugPrint('No se pudo borrar la fuente guardada: $e');
    }
    _reset();
    ref.read(activeSourceProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}

final playlistProvider =
    AsyncNotifierProvider<PlaylistController, M3uPlaylist?>(PlaylistController.new);

/// Filtro de búsqueda en memoria. TODO: sustituir por FTS5 (drift) para 50k+.
final channelSearchProvider = StateProvider<String>((ref) => '');

/// Categoría seleccionada (`null` = todas).
final selectedGroupProvider = StateProvider<String?>((ref) => null);

/// Grupos de la lista activa, en orden de aparición.
final groupsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  return {for (final c in all) if (c.group.isNotEmpty) c.group}.toList(growable: false);
});

final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final all = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  final q = ref.watch(channelSearchProvider).trim().toLowerCase();
  final group = ref.watch(selectedGroupProvider);
  if (q.isEmpty && group == null) return all;
  return all
      .where((c) => (group == null || c.group == group) && (q.isEmpty || c.name.toLowerCase().contains(q)))
      .toList(growable: false);
});

/// Canales de la lista activa por su identificador estable (`Channel.uid`): sirve para
/// convertir favoritos y recientes guardados en canales reproducibles.
final channelsByUidProvider = Provider<Map<String, Channel>>((ref) {
  final channels = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  return {for (final c in channels) c.uid: c};
});
