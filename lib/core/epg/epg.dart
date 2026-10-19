import 'dart:convert';

/// Un programa de la guía.
class EpgProgram {
  const EpgProgram({required this.title, required this.start, required this.end, this.description = ''});

  final String title;
  final DateTime start;
  final DateTime end;
  final String description;

  bool isOn(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  /// Fracción emitida (0..1) en el instante [now].
  double progress(DateTime now) {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (now.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }
}

/// Ahora y a continuación.
class NowNext {
  const NowNext(this.now, this.next);
  final EpgProgram? now;
  final EpgProgram? next;
}

String _b64(Object? v) {
  final s = '${v ?? ''}';
  if (s.isEmpty) return '';
  try {
    return utf8.decode(base64.decode(base64.normalize(s)), allowMalformed: true).trim();
  } on FormatException {
    return s; // algunos paneles lo mandan en claro
  }
}

/// Respuesta de `get_short_epg` → programas ordenados por inicio.
List<EpgProgram> parseShortEpg(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final list = json is Map ? json['epg_listings'] : null;
  if (list is! List) return const [];
  final out = <EpgProgram>[];
  for (final e in list) {
    if (e is! Map) continue;
    final s = int.tryParse('${e['start_timestamp'] ?? ''}');
    final t = int.tryParse('${e['stop_timestamp'] ?? e['end_timestamp'] ?? ''}');
    final title = _b64(e['title']);
    if (s == null || t == null || title.isEmpty) continue;
    out.add(EpgProgram(
      title: title,
      start: DateTime.fromMillisecondsSinceEpoch(s * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(t * 1000),
      description: _b64(e['description']),
    ));
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

NowNext nowNext(List<EpgProgram> programs, DateTime now) {
  EpgProgram? cur;
  EpgProgram? next;
  for (final p in programs) {
    if (p.isOn(now)) {
      cur = p;
    } else if (p.start.isAfter(now) && (next == null || p.start.isBefore(next.start))) {
      next = p;
    }
  }
  return NowNext(cur, next);
}
