# Inicializa skills, verifica agentes y genera las carpetas de plataforma de Flutter.
# Uso: ./scripts/setup.ps1 [-SkipSkills] [-SkipPlatforms]
param([switch]$SkipSkills, [switch]$SkipPlatforms)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $SkipSkills) {
    # Revisa cada skill antes de usarla: se ejecutan con permisos del agente.
    npx -y skills add https://github.com/designed-by-ai/skills --skill design-mobile-apps -y
    npx -y skills add https://github.com/wshobson/agents --skill mobile-android-design -y
    npx -y skills add https://uizze.sh/ -y
}

foreach ($a in 'iptv-stream-tester', 'm3u-epg-benchmarker', 'adaptive-layout-auditor') {
    if (-not (Test-Path ".claude/agents/$a.md")) { throw "Falta el agente .claude/agents/$a.md" }
    Write-Host "agente OK: $a"
}

if (-not $SkipPlatforms) {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter no está en PATH. Instálalo: https://docs.flutter.dev/get-started/install'
    }
    # Se genera en una carpeta temporal para no pisar lib/ ni pubspec.yaml.
    flutter create --project-name iptv_launcher --org com.iptvlauncher `
        --platforms=android,ios,windows,macos,linux _scaffold
    foreach ($p in 'android', 'ios', 'windows', 'macos', 'linux') {
        if (-not (Test-Path $p)) { Move-Item "_scaffold/$p" $p }
    }
    Remove-Item _scaffold -Recurse -Force
    flutter pub get
}
Write-Host 'Listo. Siguiente: flutter analyze; flutter test'
Write-Host 'Android: en android/app/build.gradle fija minSdk 21; macOS: habilita com.apple.security.network.client en los entitlements.'
