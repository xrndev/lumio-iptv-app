/// Limpieza de los nombres que dan los proveedores IPTV:
/// `"ES - LA SEXTA FHD◉"` → título `"LA SEXTA"` + calidad `"FHD"`.
class ChannelName {
  const ChannelName(this.title, {this.quality, this.hevc = false});

  /// Nombre sin prefijo de país, símbolos ni etiquetas de calidad.
  final String title;

  /// `4K`, `FHD`, `HD` o `SD` (la mejor que aparezca en el nombre), o `null`.
  final String? quality;

  /// El nombre indica que el flujo es HEVC/H.265.
  final bool hevc;
}

final _symbols = RegExp(r'[←-➿⬀-⯿️‍]+');
final _countryPrefix = RegExp(r'^[A-Za-z]{2}\s*[-|:]\s+');
final _qualityToken = RegExp(
  r'(?<![A-Za-z0-9])(4K|UHD|2160P?|FHD|1080P?|HD|720P?|SD|HEVC|H\.?265|50FPS|60FPS)(?![A-Za-z0-9])',
  caseSensitive: false,
);

/// Separa nombre, calidad y HEVC. Si al limpiar no queda nada, devuelve el original.
ChannelName parseChannelName(String raw) {
  var t = raw.replaceAll(_symbols, ' ').trim();
  t = t.replaceFirst(_countryPrefix, '');

  var rank = 0; // 4K=4, FHD=3, HD=2, SD=1
  var hevc = false;
  t = t.replaceAllMapped(_qualityToken, (m) {
    final q = m[1]!.toUpperCase();
    if (q == 'HEVC' || q.startsWith('H') && q.contains('265')) {
      hevc = true;
    } else if (q == '4K' || q == 'UHD' || q.startsWith('2160')) {
      rank = rank < 4 ? 4 : rank;
    } else if (q == 'FHD' || q.startsWith('1080')) {
      rank = rank < 3 ? 3 : rank;
    } else if (q == 'HD' || q.startsWith('720')) {
      rank = rank < 2 ? 2 : rank;
    } else if (q == 'SD') {
      rank = rank < 1 ? 1 : rank;
    }
    return ' ';
  });

  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  t = t.replaceAll(RegExp(r'^[-|:/,\s]+|[-|:/,\s]+$'), '');
  if (t.isEmpty) return ChannelName(raw.trim());

  const labels = {4: '4K', 3: 'FHD', 2: 'HD', 1: 'SD'};
  return ChannelName(t, quality: labels[rank], hevc: hevc);
}

final _groupSeparator = RegExp(r'\s*\|\s*');

/// `"EU | ES | TDT ESPAÑA VIP"` → `"TDT España VIP"`; `"VOD | MULTI-LANG - NEW"` →
/// `"Multi-Lang - New"`. Solo para mostrar: el filtrado sigue usando el nombre original.
String prettyGroupName(String raw) {
  final tokens = raw.split(_groupSeparator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (tokens.isEmpty) return raw.trim();
  // Fuera los prefijos de región/tipo ("EU", "ES", "VOD", "SRS"): 2–3 letras.
  while (tokens.length > 1 && RegExp(r'^[A-Za-z]{2,3}$').hasMatch(tokens.first)) {
    tokens.removeAt(0);
  }
  return tokens.map(_titleCase).join(' · ');
}

/// Siglas que deben quedar en mayúsculas al poner un grupo en "formato título".
const _acronyms = {'TDT', 'VIP', 'TV', 'HD', 'FHD', 'UHD', 'SD', 'VOD', 'USA', 'UK', 'EU', 'RTVE', 'TVE', 'M+'};

String _titleCase(String s) => s.split(' ').map((w) {
      if (w.isEmpty) return w;
      // Siglas conocidas y palabras con números o símbolos se dejan tal cual (TDT, M+, 4K).
      if (_acronyms.contains(w.toUpperCase()) || RegExp(r'[0-9+&]').hasMatch(w)) return w;
      return w.split('-').map(_capitalize).join('-');
    }).join(' ');

String _capitalize(String w) =>
    w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase();

const _fromAccents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const _toAccents = 'aaaaaeeeeiiiiooooouuuunc';

/// Minúsculas y sin tildes: para que "peliculas" encuentre "Películas".
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = _fromAccents.indexOf(ch);
    b.write(i < 0 ? ch : _toAccents[i]);
  }
  return b.toString();
}
