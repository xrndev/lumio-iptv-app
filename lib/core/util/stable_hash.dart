/// Hash estable (FNV-1a de 32 bits con dos semillas → 16 caracteres hex).
///
/// `String.hashCode` de Dart no está garantizado entre ejecuciones ni versiones, y estos
/// identificadores se guardan en disco y se comparten entre dispositivos (favoritos, caché),
/// así que tienen que dar siempre el mismo resultado. No es criptográfico.
String stableHash(String input) {
  var a = 0x811c9dc5;
  var b = 0x9747b28c;
  for (final unit in input.codeUnits) {
    a = ((a ^ unit) * 0x01000193) & 0xffffffff;
    b = ((b ^ unit) * 0x01000193) & 0xffffffff;
  }
  return a.toRadixString(16).padLeft(8, '0') + b.toRadixString(16).padLeft(8, '0');
}
