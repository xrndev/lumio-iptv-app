#!/usr/bin/env bash
# Equivalente POSIX de setup.ps1 (macOS/Linux).
set -euo pipefail
cd "$(dirname "$0")/.."

# Revisa cada skill antes de usarla: se ejecutan con permisos del agente.
npx -y skills add https://github.com/designed-by-ai/skills --skill design-mobile-apps -y
npx -y skills add https://github.com/wshobson/agents --skill mobile-android-design -y
npx -y skills add https://uizze.sh/ -y

for a in iptv-stream-tester m3u-epg-benchmarker adaptive-layout-auditor; do
  [ -f ".claude/agents/$a.md" ] || { echo "Falta el agente $a" >&2; exit 1; }
done

command -v flutter >/dev/null || { echo "Flutter no está en PATH" >&2; exit 1; }
flutter create --project-name iptv_launcher --org com.iptvlauncher \
  --platforms=android,ios,windows,macos,linux _scaffold
for p in android ios windows macos linux; do
  [ -d "$p" ] || mv "_scaffold/$p" "$p"
done
rm -rf _scaffold
flutter pub get
