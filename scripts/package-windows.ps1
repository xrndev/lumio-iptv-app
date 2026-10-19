# Genera dist/IPTV-Launcher-windows.zip con la app compilada en release, las DLL de
# Visual C++ (despliegue local: funciona en un Windows limpio) y el instalador.
# Uso: ./scripts/package-windows.ps1 [-Install]   (-Install además la instala aquí)
param([switch]$Install)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter no está en PATH. Ejecuta antes ./scripts/setup.ps1'
}

# Los avisos del compilador salen por stderr: no deben abortar (solo importa el código de salida).
$ErrorActionPreference = 'Continue'
flutter build windows --release
$buildExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($buildExit -ne 0) { throw 'flutter build windows falló' }

$release = 'build\windows\x64\runner\Release'
$stage = 'dist\IPTV-Launcher-windows'
if (Test-Path dist) { Remove-Item dist -Recurse -Force }
New-Item -ItemType Directory -Force "$stage\app" | Out-Null
Copy-Item "$release\*" "$stage\app" -Recurse

# Runtime de Visual C++ junto al .exe (redistribuible, "app-local deployment").
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $src = Join-Path $env:SystemRoot "System32\$dll"
    if (Test-Path $src) { Copy-Item $src "$stage\app" -Force }
    else { Write-Warning "No se encontró $dll en System32; la app podría requerir el runtime de VC++." }
}

Copy-Item scripts\windows\Install.ps1, scripts\windows\Install.cmd $stage
Compress-Archive -Path "$stage\*" -DestinationPath dist\IPTV-Launcher-windows.zip -Force

$mb = [math]::Round((Get-Item dist\IPTV-Launcher-windows.zip).Length / 1MB, 1)
Write-Host "Paquete listo: dist\IPTV-Launcher-windows.zip ($mb MB)"

if ($Install) { & "$stage\Install.ps1" }
