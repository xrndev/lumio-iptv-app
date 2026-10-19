# Instala Lumio para el usuario actual (no requiere administrador):
#   - copia la app a %LOCALAPPDATA%\Programs\Lumio
#   - crea accesos directos en el Escritorio y en el menú Inicio
#   - retira la instalación anterior llamada "IPTV Launcher", si existe
# Uso: doble clic en Install.cmd  (o: ./Install.ps1 [-Source <carpeta con lumio.exe>])
param(
    [string]$Source = (Join-Path $PSScriptRoot 'app'),
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'

$exeName = 'lumio.exe'
if (-not (Test-Path (Join-Path $Source $exeName))) {
    throw "No se encuentra $exeName en '$Source'. Ejecuta el instalador desde la carpeta descomprimida."
}

$dest = Join-Path $env:LOCALAPPDATA 'Programs\Lumio'
$legacyDest = Join-Path $env:LOCALAPPDATA 'Programs\IPTV Launcher'

# Cerrar la app (nueva o antigua) para poder actualizarla.
Get-Process lumio, iptv_launcher -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -like "$dest*" -or $_.Path -like "$legacyDest*" } | Stop-Process -Force

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $Source '*') $dest -Recurse -Force

function New-Shortcut([string]$path) {
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($path)
    $lnk.TargetPath = Join-Path $dest $exeName
    $lnk.WorkingDirectory = $dest
    $lnk.IconLocation = (Join-Path $dest $exeName) + ',0'
    $lnk.Description = 'Lumio'
    $lnk.Save()
}

$desktop = [Environment]::GetFolderPath('Desktop')   # respeta Escritorio redirigido (OneDrive)
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
New-Shortcut (Join-Path $desktop 'Lumio.lnk')
New-Shortcut (Join-Path $startMenu 'Lumio.lnk')

# Limpieza de la versión anterior (nombre "IPTV Launcher").
if (Test-Path $legacyDest) { Remove-Item $legacyDest -Recurse -Force }
foreach ($old in (Join-Path $desktop 'IPTV Launcher.lnk'), (Join-Path $startMenu 'IPTV Launcher.lnk')) {
    if (Test-Path $old) { Remove-Item $old -Force }
}

Write-Host "Lumio instalado en: $dest"
Write-Host "Acceso directo creado en: $desktop"
if (-not $NoLaunch) { Start-Process (Join-Path $dest $exeName) }
