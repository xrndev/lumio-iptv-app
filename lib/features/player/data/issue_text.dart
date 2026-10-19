// Texto de diagnóstico que se enseña al usuario cuando un contenido no abre.

/// Quita usuario y contraseña de URLs y parámetros (nunca deben salir en pantalla ni en
/// capturas que el usuario comparta) y acorta el texto.
String sanitizeIssue(String raw) {
  var t = raw.replaceAllMapped(
    RegExp(r'(/(?:live|movie|series)/)[^/\s]+/[^/\s]+/'),
    (m) => '${m[1]}***/***/',
  );
  t = t.replaceAllMapped(
    RegExp(r'(username|password|token)=[^&\s]+', caseSensitive: false),
    (m) => '${m[1]}=***',
  );
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length > 220 ? '${t.substring(0, 220)}…' : t;
}

final _interesting = RegExp(
  r'(http|failed|refused|time.?out|timed out|forbidden|unauthori[sz]ed|server returned|'
  r'connection|resolve|ssl|certificate|invalid|unsupported|not found)',
  caseSensitive: false,
);
final _noise = RegExp(
  r'(property not found|libmpv_render|file cache|egl|metal|opengl|hwdec|vo/|shader)',
  caseSensitive: false,
);

/// ¿Esta línea del registro de libmpv ayuda a explicar un fallo de apertura?
bool isInterestingIssue(String text) => _interesting.hasMatch(text) && !_noise.hasMatch(text);
