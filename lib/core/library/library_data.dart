import 'dart:convert';
import 'dart:io';

/// Biblioteca del usuario por fuente: favoritos, recientes y progreso de reproducción.
///
/// Todo está pensado para **fusionarse entre dispositivos**: cada elemento lleva la marca de
/// tiempo de su último cambio (`t`, ms desde 1970) y gana el más reciente; los borrados se
/// guardan como "tumbas" (`removed`) para que un dispositivo no resucite lo que otro quitó.
/// Es un tipo de dato CRDT sencillo (último escritor gana por elemento): fusionar es
/// conmutativo, asociativo e idempotente, así que da igual el orden o cuántas veces se haga.
enum LibraryKind { channel, movie, series }

/// Cuánto se conservan las tumbas de favoritos quitados.
const _tombstoneTtl = Duration(days: 90);

/// Máximo de canales recientes.
const maxRecents = 50;

class FavoriteEntry {
  const FavoriteEntry(this.uid, this.t, {this.removed = false});

  final String uid;
  final int t;
  final bool removed;

  Map<String, Object?> toJson() => {'u': uid, 't': t, if (removed) 'd': true};

  static FavoriteEntry? fromJson(Object? j) {
    if (j is! Map || j['u'] is! String || j['t'] is! int) return null;
    return FavoriteEntry(j['u'] as String, j['t'] as int, removed: j['d'] == true);
  }
}

class RecentEntry {
  const RecentEntry(this.uid, this.t);

  final String uid;
  final int t;

  Map<String, Object?> toJson() => {'u': uid, 't': t};

  static RecentEntry? fromJson(Object? j) {
    if (j is! Map || j['u'] is! String || j['t'] is! int) return null;
    return RecentEntry(j['u'] as String, j['t'] as int);
  }
}

/// Progreso de una película o episodio. Guarda lo necesario para mostrarlo en "Continuar
/// viendo" y reanudarlo sin tener cargado el catálogo.
class ProgressEntry {
  const ProgressEntry({
    required this.key,
    required this.isEpisode,
    required this.id,
    required this.ext,
    required this.title,
    required this.posMs,
    required this.durMs,
    required this.t,
    this.poster = '',
    this.subtitle = '',
    this.hidden = false,
  });

  /// Clave estable: `m<id>` (película) o `e<id>` (episodio).
  final String key;
  final bool isEpisode;
  final int id;
  final String ext;
  final String title;
  final String poster;

  /// Para episodios: "Temporada 2 · Episodio 5".
  final String subtitle;
  final int posMs;
  final int durMs;
  final int t;

  /// El usuario lo quitó de "Continuar viendo".
  final bool hidden;

  double get fraction => durMs <= 0 ? 0 : (posMs / durMs).clamp(0.0, 1.0);

  /// Visto: llegó al 92 % o quedaba menos de un minuto.
  bool get finished => durMs > 0 && (posMs / durMs >= 0.92 || durMs - posMs < 60000);

  /// Posición desde la que reanudar; `null` si empezó hace nada (<30 s) o ya terminó.
  Duration? get resumeAt =>
      (!finished && posMs >= 30000) ? Duration(milliseconds: posMs) : null;

  bool get inContinueWatching => !hidden && resumeAt != null;

  ProgressEntry copyWith({bool? hidden, int? t}) => ProgressEntry(
        key: key,
        isEpisode: isEpisode,
        id: id,
        ext: ext,
        title: title,
        poster: poster,
        subtitle: subtitle,
        posMs: posMs,
        durMs: durMs,
        t: t ?? this.t,
        hidden: hidden ?? this.hidden,
      );

  Map<String, Object?> toJson() => {
        'k': key,
        'e': isEpisode ? 1 : 0,
        'i': id,
        'x': ext,
        'n': title,
        if (poster.isNotEmpty) 'p': poster,
        if (subtitle.isNotEmpty) 's': subtitle,
        'pos': posMs,
        'dur': durMs,
        't': t,
        if (hidden) 'h': true,
      };

  static ProgressEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final k = j['k'], i = j['i'], n = j['n'], pos = j['pos'], dur = j['dur'], t = j['t'];
    if (k is! String || i is! int || n is! String || pos is! int || dur is! int || t is! int) {
      return null;
    }
    return ProgressEntry(
      key: k,
      isEpisode: j['e'] == 1,
      id: i,
      ext: '${j['x'] ?? 'mp4'}',
      title: n,
      poster: '${j['p'] ?? ''}',
      subtitle: '${j['s'] ?? ''}',
      posMs: pos,
      durMs: dur,
      t: t,
      hidden: j['h'] == true,
    );
  }
}

class SourceLibrary {
  const SourceLibrary({
    this.favorites = const {},
    this.recents = const {},
    this.progress = const {},
  });

  static const empty = SourceLibrary();

  /// Por tipo, uid → entrada.
  final Map<LibraryKind, Map<String, FavoriteEntry>> favorites;

  /// Canales vistos, uid → entrada.
  final Map<String, RecentEntry> recents;

  /// Progreso, clave → entrada.
  final Map<String, ProgressEntry> progress;

  // --- Favoritos -------------------------------------------------------------

  bool isFavorite(LibraryKind kind, String uid) {
    final e = favorites[kind]?[uid];
    return e != null && !e.removed;
  }

  /// Favoritos en el orden en que se añadieron.
  List<String> favoriteUids(LibraryKind kind) {
    final live = (favorites[kind] ?? const <String, FavoriteEntry>{})
        .values
        .where((e) => !e.removed)
        .toList()
      ..sort((a, b) => a.t.compareTo(b.t));
    return [for (final e in live) e.uid];
  }

  SourceLibrary toggleFavorite(LibraryKind kind, String uid, int now) {
    final next = {for (final k in favorites.keys) k: Map.of(favorites[k]!)};
    final byKind = next.putIfAbsent(kind, () => {});
    final removing = isFavorite(kind, uid);
    byKind[uid] = FavoriteEntry(uid, now, removed: removing);
    return SourceLibrary(favorites: next, recents: recents, progress: progress);
  }

  // --- Recientes -------------------------------------------------------------

  SourceLibrary addRecent(String uid, int now) {
    final next = Map.of(recents)..[uid] = RecentEntry(uid, now);
    return SourceLibrary(favorites: favorites, recents: _capRecents(next), progress: progress);
  }

  SourceLibrary clearRecents() =>
      SourceLibrary(favorites: favorites, recents: const {}, progress: progress);

  /// Más reciente primero.
  List<String> recentUids() {
    final list = recents.values.toList()..sort((a, b) => b.t.compareTo(a.t));
    return [for (final e in list) e.uid];
  }

  static Map<String, RecentEntry> _capRecents(Map<String, RecentEntry> m) {
    if (m.length <= maxRecents) return m;
    final keep = (m.values.toList()..sort((a, b) => b.t.compareTo(a.t))).take(maxRecents);
    return {for (final e in keep) e.uid: e};
  }

  // --- Progreso --------------------------------------------------------------

  SourceLibrary saveProgress(ProgressEntry entry) => SourceLibrary(
        favorites: favorites,
        recents: recents,
        progress: Map.of(progress)..[entry.key] = entry,
      );

  /// Quita un elemento de "Continuar viendo" sin perder que se vio (se oculta).
  SourceLibrary hideProgress(String key, int now) {
    final e = progress[key];
    if (e == null) return this;
    return saveProgress(e.copyWith(hidden: true, t: now));
  }

  /// "Continuar viendo": lo empezado y sin terminar, lo último visto primero.
  List<ProgressEntry> continueWatching() =>
      progress.values.where((e) => e.inContinueWatching).toList()
        ..sort((a, b) => b.t.compareTo(a.t));

  ProgressEntry? progressOf(String key) => progress[key];

  // --- Fusión ----------------------------------------------------------------

  /// Fusiona con la biblioteca de otro dispositivo: por elemento gana el cambio más reciente.
  SourceLibrary merge(SourceLibrary other) {
    final favs = <LibraryKind, Map<String, FavoriteEntry>>{};
    for (final kind in {...favorites.keys, ...other.favorites.keys}) {
      final a = favorites[kind] ?? const <String, FavoriteEntry>{};
      final b = other.favorites[kind] ?? const <String, FavoriteEntry>{};
      favs[kind] = {
        for (final uid in {...a.keys, ...b.keys}) uid: _newer(a[uid], b[uid], (e) => e.t)!,
      };
    }
    final rec = {
      for (final uid in {...recents.keys, ...other.recents.keys})
        uid: _newer(recents[uid], other.recents[uid], (e) => e.t)!,
    };
    final prog = {
      for (final k in {...progress.keys, ...other.progress.keys})
        k: _newer(progress[k], other.progress[k], (e) => e.t)!,
    };
    return SourceLibrary(favorites: favs, recents: _capRecents(rec), progress: prog);
  }

  static T? _newer<T>(T? a, T? b, int Function(T) t) {
    if (a == null) return b;
    if (b == null) return a;
    return t(b) > t(a) ? b : a; // empate: se conserva el local, el resultado es igual
  }

  /// Elimina las tumbas antiguas (ya habrán llegado a los demás dispositivos).
  SourceLibrary pruned(int now) {
    final limit = now - _tombstoneTtl.inMilliseconds;
    final favs = {
      for (final e in favorites.entries)
        e.key: {
          for (final f in e.value.entries)
            if (!(f.value.removed && f.value.t < limit)) f.key: f.value,
        },
    };
    return SourceLibrary(favorites: favs, recents: recents, progress: progress);
  }

  // --- JSON ------------------------------------------------------------------

  Map<String, Object?> toJson() => {
        // Orden fijo (por clave): dos bibliotecas con el mismo contenido dan el mismo JSON
        // aunque se hayan fusionado en distinto orden.
        'fav': {
          for (final kind in LibraryKind.values)
            if (favorites[kind] != null)
              kind.name: [
                for (final uid in (favorites[kind]!.keys.toList()..sort()))
                  favorites[kind]![uid]!.toJson(),
              ],
        },
        'rec': [
          for (final uid in (recents.keys.toList()..sort())) recents[uid]!.toJson(),
        ],
        'prog': [
          for (final k in (progress.keys.toList()..sort())) progress[k]!.toJson(),
        ],
      };

  static SourceLibrary fromJson(Object? j) {
    if (j is! Map) return empty;
    final favs = <LibraryKind, Map<String, FavoriteEntry>>{};
    final fav = j['fav'];
    if (fav is Map) {
      for (final kind in LibraryKind.values) {
        final list = fav[kind.name];
        if (list is List) {
          final map = <String, FavoriteEntry>{};
          for (final raw in list) {
            final e = FavoriteEntry.fromJson(raw);
            if (e != null) map[e.uid] = e;
          }
          favs[kind] = map;
        }
      }
    }
    final rec = <String, RecentEntry>{};
    if (j['rec'] is List) {
      for (final raw in j['rec'] as List) {
        final e = RecentEntry.fromJson(raw);
        if (e != null) rec[e.uid] = e;
      }
    }
    final prog = <String, ProgressEntry>{};
    if (j['prog'] is List) {
      for (final raw in j['prog'] as List) {
        final e = ProgressEntry.fromJson(raw);
        if (e != null) prog[e.key] = e;
      }
    }
    return SourceLibrary(favorites: favs, recents: _capRecents(rec), progress: prog);
  }
}

/// Todas las bibliotecas, por id de fuente (`SavedSource.id`).
class LibraryData {
  const LibraryData([this.sources = const {}]);

  final Map<String, SourceLibrary> sources;

  SourceLibrary of(String sourceId) => sources[sourceId] ?? SourceLibrary.empty;

  LibraryData withSource(String sourceId, SourceLibrary lib) =>
      LibraryData({...sources, sourceId: lib});

  Map<String, Object?> toJson() => {
        'v': 1,
        'sources': {for (final e in sources.entries) e.key: e.value.toJson()},
      };

  static LibraryData fromJson(Object? j) {
    if (j is! Map || j['sources'] is! Map) return const LibraryData();
    return LibraryData({
      for (final e in (j['sources'] as Map).entries)
        if (e.key is String) e.key as String: SourceLibrary.fromJson(e.value),
    });
  }
}

// --- Código para pasar la biblioteca a otro dispositivo -------------------------------------

const _shareMagic = 'LUMIO1.';

/// Código de texto (copiar y pegar) con la biblioteca de una fuente: gzip + base64.
String encodeShareCode(String sourceId, SourceLibrary lib) {
  final json = jsonEncode({'v': 1, 's': sourceId, 'l': lib.toJson()});
  return _shareMagic + base64Url.encode(gzip.encode(utf8.encode(json)));
}

/// Inversa de [encodeShareCode]; `null` si el código no es válido.
({String sourceId, SourceLibrary library})? decodeShareCode(String code) {
  try {
    final c = code.trim();
    if (!c.startsWith(_shareMagic)) return null;
    final bytes = gzip.decode(base64Url.decode(c.substring(_shareMagic.length)));
    final j = jsonDecode(utf8.decode(bytes));
    if (j is! Map || j['v'] != 1 || j['s'] is! String) return null;
    return (sourceId: j['s'] as String, library: SourceLibrary.fromJson(j['l']));
  } catch (_) {
    return null;
  }
}
