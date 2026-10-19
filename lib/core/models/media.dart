/// Elemento de catálogo (película o serie) mostrable en una rejilla de pósteres.
abstract class MediaEntry {
  int get id;
  String get title;
  String get poster;
  double? get rating;
  String get group;
  String get year;
}

enum MediaKind { movies, series }

/// Quita prefijos de idioma y sufijos de proveedor: "ES - The Storm - 2026 (SUB)" → "The Storm".
String cleanTitle(String raw) {
  var t = raw.trim();
  t = t.replaceFirst(RegExp(r'^[A-Z]{2,3}\s*[-|:]\s*'), '');
  t = t.replaceAll(RegExp(r'\s*[-–]\s*(19|20)\d{2}\b'), '');
  t = t.replaceAll(
      RegExp(r'\s*[\(\[](SUB|MULTI-SUB|MULTI|DUAL|LAT|CAST)[\)\]]', caseSensitive: false), '');
  return t.trim().isEmpty ? raw.trim() : t.trim();
}

class VodItem implements MediaEntry {
  const VodItem({
    required this.id,
    required this.title,
    required this.poster,
    required this.group,
    required this.ext,
    this.rating,
    this.year = '',
  });

  @override
  final int id;
  @override
  final String title;
  @override
  final String poster;
  @override
  final String group;
  @override
  final double? rating;
  @override
  final String year;

  /// Extensión del contenedor (`mp4`, `mkv`…).
  final String ext;
}

class SeriesItem implements MediaEntry {
  const SeriesItem({
    required this.id,
    required this.title,
    required this.poster,
    required this.group,
    this.rating,
    this.year = '',
    this.plot = '',
    this.genre = '',
    this.backdrop = '',
  });

  @override
  final int id;
  @override
  final String title;
  @override
  final String poster;
  @override
  final String group;
  @override
  final double? rating;
  @override
  final String year;
  final String plot;
  final String genre;
  final String backdrop;
}

class MediaCatalog {
  const MediaCatalog({required this.items, required this.groups});
  final List<MediaEntry> items;

  /// Categorías con contenido, en el orden que da el servidor.
  final List<String> groups;
}

class VodDetail {
  const VodDetail({
    this.plot = '',
    this.genre = '',
    this.duration = '',
    this.releaseDate = '',
    this.cast = '',
    this.director = '',
    this.backdrop = '',
  });

  final String plot;
  final String genre;
  final String duration;
  final String releaseDate;
  final String cast;
  final String director;
  final String backdrop;
}

class Episode {
  const Episode({
    required this.id,
    required this.season,
    required this.number,
    required this.title,
    required this.ext,
    this.durationSecs,
    this.plot = '',
    this.image = '',
  });

  final int id;
  final int season;
  final int number;
  final String title;
  final String ext;
  final int? durationSecs;
  final String plot;
  final String image;
}

class SeriesDetail {
  const SeriesDetail({
    required this.seasons,
    this.plot = '',
    this.genre = '',
    this.cast = '',
    this.backdrop = '',
  });

  /// Temporada → episodios, ordenado por número de temporada.
  final Map<int, List<Episode>> seasons;
  final String plot;
  final String genre;
  final String cast;
  final String backdrop;
}
