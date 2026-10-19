# Prepara un Windows para desarrollar: instala/comprueba Git, Flutter, Modo desarrollador,
# C++ ATL, dependencias del proyecto y (opcional) las skills de diseño. Es idempotente.
# Uso: ./scripts/setup.ps1 [-SkipSkills]
param([switch]$SkipSkills)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Has($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}
# Los programas nativos escriben avisos por stderr: solo importa el código de salida.
function Run([scriptblock]$b) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $b; $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    if ($code -ne 0) { throw "Comando falló con código $code" }
}
function Elevated([string]$command) {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', $command
}

# 1. Git
if (-not (Has git)) {
    Step 'Instalando Git (winget)'
    if (-not (Has winget)) { throw 'Falta winget. Instala Git desde https://git-scm.com y vuelve a ejecutar.' }
    Run { winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements }
    Refresh-Path
}

# 2. Flutter
if (-not (Has flutter)) {
    $home_ = Join-Path $env:USERPROFILE 'dev\flutter'
    if (-not (Test-Path "$home_\bin\flutter.bat")) {
        Step "Descargando Flutter (stable) en $home_"
        Run { git clone --depth 1 -b stable https://github.com/flutter/flutter.git $home_ }
    }
    $env:Path = "$home_\bin;$env:Path"
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($user -notlike "*$home_\bin*") {
        [Environment]::SetEnvironmentVariable('Path', "$home_\bin;$user", 'User')   # permanente
    }
}
Step ('Flutter: ' + ((flutter --version 2>$null | Select-Object -First 1)))

# 3. Modo desarrollador (symlinks que exigen los plugins)
# (No se puede probar creando un symlink: PowerShell 5.1 exige administrador aunque
# el Modo desarrollador esté activo. Se consulta el valor de registro.)
$devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
        -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -ne 1) {
    Step 'Activando el Modo desarrollador (aparecerá un aviso de administrador)'
    Elevated 'New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Force | Out-Null; Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord'
}

# 4. Visual Studio con C++ y ATL
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsPath = if (Test-Path $vswhere) {
    & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
}
if (-not $vsPath) {
    Step 'Instalando Visual Studio Build Tools con C++ y ATL (puede tardar varios minutos)'
    Run { winget install -e --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATL --includeRecommended' }
} elseif (-not (& $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.ATL -property installationPath)) {
    Step 'Añadiendo el componente C++ ATL (aparecerá un aviso de administrador)'
    $setup = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe"
    Elevated "& '$setup' modify --installPath '$vsPath' --add Microsoft.VisualStudio.Component.VC.ATL --quiet --norestart"
}

# 5. Dependencias del proyecto
Step 'flutter pub get'
Run { flutter pub get }

# 6. Skills de diseño (opcional; requieren Node.js)
if (-not $SkipSkills -and (Has npx)) {
    Step 'Instalando skills de diseño'
    Run { npx -y skills add https://github.com/designed-by-ai/skills --skill design-mobile-apps -y }
    Run { npx -y skills add https://github.com/wshobson/agents --skill mobile-android-design -y }
    Run { npx -y skills add https://uizze.sh/ -y }
}

foreach ($a in 'iptv-stream-tester', 'm3u-epg-benchmarker', 'adaptive-layout-auditor') {
    if (-not (Test-Path ".claude/agents/$a.md")) { throw "Falta el agente .claude/agents/$a.md" }
}

Write-Host ''
Write-Host 'Listo.' -ForegroundColor Green
Write-Host '  Probar:               flutter run -d windows'
Write-Host '  Instalar con acceso:  ./scripts/package-windows.ps1 -Install'
