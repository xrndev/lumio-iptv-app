#!/usr/bin/env bash
# Instala IPTV Launcher para el usuario actual en Linux:
#  - instala las librerías de sistema que necesita (libmpv, GTK, libsecret) si faltan
#  - copia la app a ~/.local/share/iptv-launcher y crea el lanzador del menú/escritorio
# Uso: ./install.sh        (pide sudo solo si hay que instalar librerías)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/app"
[ -x "$SRC/iptv_launcher" ] || { echo "No se encuentra $SRC/iptv_launcher. Ejecuta el instalador desde la carpeta descomprimida." >&2; exit 1; }

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

install_libs() {
  if command -v apt-get >/dev/null; then
    $SUDO apt-get update -y
    # libmpv2 en Debian 12+/Ubuntu 22.04+; libmpv1 en versiones anteriores.
    $SUDO apt-get install -y libgtk-3-0 libsecret-1-0 libjsoncpp25 libegl1 libgl1 \
      && ($SUDO apt-get install -y libmpv2 || $SUDO apt-get install -y libmpv1)
  elif command -v dnf >/dev/null; then
    $SUDO dnf install -y gtk3 libsecret jsoncpp mesa-libEGL mesa-libGL mpv-libs
  elif command -v pacman >/dev/null; then
    $SUDO pacman -S --needed --noconfirm gtk3 libsecret jsoncpp mpv
  elif command -v zypper >/dev/null; then
    $SUDO zypper --non-interactive install gtk3 libsecret-1-0 libjsoncpp25 libmpv2
  else
    echo "Gestor de paquetes no reconocido: instala manualmente libmpv, GTK 3 y libsecret." >&2
  fi
}

# ¿Falta alguna librería dinámica?
if ldd "$SRC/iptv_launcher" "$SRC"/lib/*.so 2>/dev/null | grep -q "not found"; then
  echo "Instalando librerías necesarias…"
  install_libs
fi
# libmpv no va dentro del paquete: comprobar que existe.
if ! ldconfig -p 2>/dev/null | grep -q "libmpv.so"; then
  echo "Instalando libmpv…"
  install_libs
fi

DEST="$HOME/.local/share/iptv-launcher"
rm -rf "$DEST"
mkdir -p "$DEST" "$HOME/.local/bin" "$HOME/.local/share/applications"
cp -r "$SRC/." "$DEST/"
chmod +x "$DEST/iptv_launcher"
ln -sf "$DEST/iptv_launcher" "$HOME/.local/bin/iptv-launcher"

DESKTOP_FILE="$HOME/.local/share/applications/iptv-launcher.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=IPTV Launcher
Comment=Reproductor IPTV
Exec=$DEST/iptv_launcher
Icon=video-display
Terminal=false
Categories=AudioVideo;Video;Player;
EOF
chmod +x "$DESKTOP_FILE"

# Acceso directo en el escritorio (si existe la carpeta).
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$DESK" ]; then
  cp "$DESKTOP_FILE" "$DESK/IPTV Launcher.desktop"
  chmod +x "$DESK/IPTV Launcher.desktop"
  gio set "$DESK/IPTV Launcher.desktop" metadata::trusted true 2>/dev/null || true
fi

echo "IPTV Launcher instalado en $DEST"
echo "Ábrelo desde el menú de aplicaciones o con: iptv-launcher"
