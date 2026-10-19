# Instala IPTV Launcher para el usuario actual (no requiere administrador):
#   - copia la app a %LOCALAPPDATA%\Programs\IPTV Launcher
#   - crea accesos directos en el Escritorio y en el menú Inicio
# Uso: doble clic en Install.cmd  (o: ./Install.ps1 [-Source <carpeta con iptv_launcher.exe>])
param(
    [string]$Source = (Join-Path $PSScriptRoot 'app'),
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'

$exeName = 'iptv_launcher.exe'
if (-not (Test-Path (Join-Path $Source $exeName))) {
    throw "No se encuentra $exeName en '$Source'. Ejecuta el instalador desde la carpeta descomprimida."
}

$dest = Join-Path $env:LOCALAPPDATA 'Programs\IPTV Launcher'
Get-Process iptv_launcher -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -like "$dest*" } | Stop-Process -Force   # actualizar con la app cerrada

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $Source '*') $dest -Recurse -Force

function New-Shortcut([string]$path) {
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($path)
    $lnk.TargetPath = Join-Path $dest $exeName
    $lnk.WorkingDirectory = $dest
    $lnk.IconLocation = (Join-Path $dest $exeName) + ',0'
    $lnk.Description = 'IPTV Launcher'
    $lnk.Save()
}

$desktop = [Environment]::GetFolderPath('Desktop')   # respeta Escritorio redirigido (OneDrive)
New-Shortcut (Join-Path $desktop 'IPTV Launcher.lnk')
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
New-Shortcut (Join-Path $startMenu 'IPTV Launcher.lnk')

Write-Host "IPTV Launcher instalado en: $dest"
Write-Host "Acceso directo creado en: $desktop"
if (-not $NoLaunch) { Start-Process (Join-Path $dest $exeName) }
