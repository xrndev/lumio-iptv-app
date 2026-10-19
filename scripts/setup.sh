#!/usr/bin/env bash
# Prepara macOS o Linux para desarrollar: instala/comprueba Flutter y las dependencias de
# compilación del sistema, y ejecuta flutter pub get. Idempotente.
# Uso: ./scripts/setup.sh [--skip-skills]
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }
SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO="sudo"

OS="$(uname -s)"

# 1. Dependencias del sistema
if [ "$OS" = "Linux" ]; then
  step "Dependencias de compilación de Linux"
  if has apt-get; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y git curl unzip xz-utils clang cmake ninja-build pkg-config \
      libgtk-3-dev libmpv-dev mpv libsecret-1-dev libjsoncpp-dev libegl1 libgl1
  elif has dnf; then
    $SUDO dnf install -y git curl unzip xz clang cmake ninja-build pkgconf-pkg-config \
      gtk3-devel mpv-devel libsecret-devel jsoncpp-devel mesa-libEGL mesa-libGL
  elif has pacman; then
    $SUDO pacman -S --needed --noconfirm git curl unzip xz clang cmake ninja pkgconf gtk3 mpv libsecret jsoncpp
  else
    echo "Instala manualmente: git, clang, cmake, ninja, pkg-config, GTK3, libmpv, libsecret, jsoncpp" >&2
  fi
elif [ "$OS" = "Darwin" ]; then
  step "Herramientas de Xcode"
  xcode-select -p >/dev/null 2>&1 || xcode-select --install || true
  has pod || { has brew && brew install cocoapods; }
fi

# 2. Flutter
if ! has flutter; then
  FLUTTER_HOME="$HOME/dev/flutter"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    step "Descargando Flutter (stable) en $FLUTTER_HOME"
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] && ! grep -q "dev/flutter/bin" "$rc" && echo 'export PATH="$HOME/dev/flutter/bin:$PATH"' >> "$rc"
  done
fi
step "Flutter: $(flutter --version 2>/dev/null | head -1)"

# 3. Dependencias del proyecto
step "flutter pub get"
flutter pub get

# 4. Skills de diseño (opcional; requieren Node.js)
if [ "${1:-}" != "--skip-skills" ] && has npx; then
  step "Instalando skills de diseño"
  npx -y skills add https://github.com/designed-by-ai/skills --skill design-mobile-apps -y
  npx -y skills add https://github.com/wshobson/agents --skill mobile-android-design -y
  npx -y skills add https://uizze.sh/ -y
fi

for a in iptv-stream-tester m3u-epg-benchmarker adaptive-layout-auditor; do
  [ -f ".claude/agents/$a.md" ] || { echo "Falta el agente $a" >&2; exit 1; }
done

echo
echo "Listo."
echo "  Probar:    flutter run -d $( [ "$OS" = Darwin ] && echo macos || echo linux )"
echo "  Empaquetar: ./scripts/package.sh"
