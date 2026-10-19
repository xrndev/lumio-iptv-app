#!/usr/bin/env bash
# Genera el paquete distribuible de la plataforma actual en dist/:
#   Linux  → Lumio-linux-x64.tar.gz (con install.sh)
#   macOS  → Lumio-macos.zip        (.app sin firmar)
# Windows usa scripts/package-windows.ps1; Android: flutter build apk --release.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo "Flutter no está en PATH. Ejecuta antes ./scripts/setup.sh" >&2; exit 1; }

rm -rf dist && mkdir -p dist
case "$(uname -s)" in
  Linux)
    flutter build linux --release
    STAGE="dist/Lumio-linux-x64"
    mkdir -p "$STAGE/app"
    cp -r build/linux/x64/release/bundle/. "$STAGE/app/"
    cp scripts/linux/install.sh "$STAGE/install.sh"
    cp assets/branding/lumio_icon_round.png "$STAGE/lumio.png"
    chmod +x "$STAGE/install.sh"
    tar -C dist -czf dist/Lumio-linux-x64.tar.gz Lumio-linux-x64
    echo "Paquete listo: dist/Lumio-linux-x64.tar.gz"
    ;;
  Darwin)
    flutter build macos --release
    ditto -c -k --keepParent build/macos/Build/Products/Release/Lumio.app dist/Lumio-macos.zip
    echo "Paquete listo: dist/Lumio-macos.zip"
    echo "App sin firmar: la primera vez, clic derecho → Abrir."
    ;;
  *) echo "Sistema no soportado por este script" >&2; exit 1 ;;
esac
