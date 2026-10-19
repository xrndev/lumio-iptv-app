#!/usr/bin/env bash
# Ejecuta una prueba de integración en macOS y valida el resultado que imprime la propia prueba.
# Uso: run_macos_test.sh <archivo_de_prueba> "<nombre exacto del test>"
#
# En los ejecutores de CI (sin sesión gráfica) `open` no puede poner la app en primer plano
# ("Failed to foreground app") y `flutter test` devuelve 79 "No tests were found" aunque la
# prueba corre y pasa, así que no se puede fiar del código de salida.
set -u
file="$1"; name="$2"
log="$(mktemp)"
flutter test "$file" -d macos 2>&1 | tee "$log"
if grep -q "❌" "$log"; then echo "FALLÓ en macOS: $name"; exit 1; fi
if grep -q "✅ $name" "$log"; then echo "OK en macOS: $name"; exit 0; fi
echo "La prueba no llegó a ejecutarse en macOS: $name"; exit 1
