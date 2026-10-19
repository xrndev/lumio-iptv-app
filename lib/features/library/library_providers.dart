import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/library/library_data.dart';
import '../../core/storage/atomic_json.dart';
import '../playlists/playlist_providers.dart';

/// Dónde se guarda la biblioteca. Sustituible en tests.
final libraryFileProvider = Provider<Future<File> Function()>((ref) => () async {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}${Platform.pathSeparator}lumio_library.json');
    });

/// Resultado de importar un código de otro dispositivo.
enum ImportResult { merged, invalidCode, otherSource }

/// Favoritos, recientes y progreso de todas las fuentes, con guardado en disco.
class LibraryNotifier extends AsyncNotifier<LibraryData> {
  Timer? _debounce;
  bool _dirty = false;
  File? _file;
  AppLifecycleListener? _lifecycle;

  @override
  Future<LibraryData> build() async {
    ref.onDispose(() {
      _debounce?.cancel();
      _lifecycle?.dispose();
      if (_dirty) unawaited(_write(state.valueOrNull)); // último volcado al cerrar
    });
    // Al pasar a segundo plano o cerrar, se guarda ya (el sistema puede matar la app).
    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      if (s != AppLifecycleState.resumed) unawaited(flush());
    });
    _file = await ref.read(libraryFileProvider)();
    return LibraryData.fromJson(await readJsonFile(_file!));
  }

  String get _sourceId => ref.read(activeSourceProvider)?.id ?? '_';

  Future<void> _update(SourceLibrary Function(SourceLibrary) change, {bool immediate = false}) async {
    final data = await future;
    final id = _sourceId;
    state = AsyncData(data.withSource(id, change(data.of(id))));
    _dirty = true;
    _debounce?.cancel();
    if (immediate) {
      await flush();
    } else {
      _debounce = Timer(const Duration(seconds: 2), () => unawaited(flush()));
    }
  }

  /// Guarda en disco lo pendiente.
  Future<void> flush() async {
    _debounce?.cancel();
    if (!_dirty) return;
    _dirty = false;
    await _write(state.valueOrNull);
  }

  Future<void> _write(LibraryData? data) async {
    final file = _file;
    if (data == null || file == null) return;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await writeJsonAtomic(
        file,
        LibraryData({for (final e in data.sources.entries) e.key: e.value.pruned(now)}).toJson(),
      );
    } catch (e) {
      debugPrint('No se pudo guardar la biblioteca: $e');
      _dirty = true; // se reintentará en el siguiente cambio
    }
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<void> toggleFavorite(LibraryKind kind, String uid) =>
      _update((l) => l.toggleFavorite(kind, uid, _now), immediate: true);

  Future<void> addRecent(String uid) => _update((l) => l.addRecent(uid, _now));

  Future<void> clearRecents() => _update((l) => l.clearRecents(), immediate: true);

  /// Guarda el progreso de una película o episodio. Se llama a menudo: se agrupa el guardado.
  Future<void> saveProgress(ProgressEntry entry) => _update((l) => l.saveProgress(entry));

  Future<void> hideProgress(String key) =>
      _update((l) => l.hideProgress(key, _now), immediate: true);

  /// Código para copiar a otro dispositivo con la biblioteca de la fuente actual.
  Future<String> exportCode() async {
    final data = await future;
    final id = _sourceId;
    return encodeShareCode(id, data.of(id));
  }

  /// Fusiona el código de otro dispositivo. Solo vale si es de la misma fuente: los
  /// identificadores de canales y películas son propios de cada proveedor.
  Future<ImportResult> importCode(String code) async {
    final decoded = decodeShareCode(code);
    if (decoded == null) return ImportResult.invalidCode;
    if (decoded.sourceId != _sourceId) return ImportResult.otherSource;
    await _update((l) => l.merge(decoded.library), immediate: true);
    return ImportResult.merged;
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, LibraryData>(LibraryNotifier.new);

/// Biblioteca de la fuente activa (vacía mientras carga).
final currentLibraryProvider = Provider<SourceLibrary>((ref) {
  final data = ref.watch(libraryProvider).valueOrNull;
  final id = ref.watch(activeSourceProvider)?.id ?? '_';
  return data?.of(id) ?? SourceLibrary.empty;
});

typedef FavoriteKey = ({LibraryKind kind, String uid});

/// ¿Es favorito? Solo reconstruye a quien lo mira cuando cambia ese elemento.
final isFavoriteProvider = Provider.family<bool, FavoriteKey>((ref, k) {
  return ref.watch(currentLibraryProvider.select((l) => l.isFavorite(k.kind, k.uid)));
});
