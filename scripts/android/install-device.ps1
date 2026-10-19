# Instala Lumio por red (adb) en un Fire TV / Fire Stick, Android TV o móvil Android.
#
# Fire TV / Fire Stick: Ajustes → Mi Fire TV → Opciones para desarrolladores →
#   "Depuración ADB" = Sí  y  "Aplicaciones de orígenes desconocidos" = Sí.
#   La IP está en Ajustes → Mi Fire TV → Acerca de → Red.
# Móvil Android 11+: Opciones de desarrollador → Depuración inalámbrica → Emparejar con
#   código (adb pair <ip:puerto> <código>) y luego usar el puerto de la pantalla principal.
#
# Uso: ./scripts/android/install-device.ps1 -Ip 192.168.1.50 [-Port 5555] [-Apk ruta.apk] [-NoLaunch]
param(
    [Parameter(Mandatory = $true)][string]$Ip,
    [int]$Port = 5555,
    [string]$Apk = 'build\app\outputs\flutter-apk\app-release.apk',
    [switch]$NoLaunch
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)

$package = 'app.lumio.player'
$minSdk = 24

# --- localizar adb ---
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) {
    foreach ($root in $env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk") {
        if ($root -and (Test-Path "$root\platform-tools\adb.exe")) { $adb = "$root\platform-tools\adb.exe"; break }
    }
}
if (-not $adb) { throw 'No se encuentra adb. Instala las platform-tools del SDK de Android.' }
if (-not (Test-Path $Apk)) { throw "No existe el APK: $Apk (compílalo con: flutter build apk --release)" }

# adb escribe avisos por stderr: solo importa el resultado.
function Adb { $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'; $out = & $adb @args 2>&1; $ErrorActionPreference = $old; $out }

$target = "${Ip}:$Port"
Write-Host "Conectando con $target ..."
$conn = (Adb connect $target) -join ' '
if ($conn -notmatch 'connected') {
    throw "No se pudo conectar: $conn`n¿Está activada la depuración por red y es la IP correcta? En el Fire TV acepta el aviso 'Permitir depuración USB' en pantalla."
}
$state = (Adb -s $target get-state) -join ''
if ($state -notmatch 'device') {
    throw "El dispositivo responde pero no está autorizado ($state). Acepta el aviso de depuración en la pantalla del dispositivo y repite."
}

# --- información del dispositivo ---
$model = (Adb -s $target shell getprop ro.product.model) -join ''
$sdk = [int](((Adb -s $target shell getprop ro.build.version.sdk) -join '').Trim())
$abi = (Adb -s $target shell getprop ro.product.cpu.abilist) -join ''
$fire = (Adb -s $target shell pm list features) -join "`n" -match 'amazon\.hardware\.fire_tv'
Write-Host ("Dispositivo: {0} · Android API {1} · {2}{3}" -f $model.Trim(), $sdk, $abi.Trim(), $(if ($fire) { ' · Fire TV' } else { '' }))
if ($sdk -lt $minSdk) {
    throw "Este dispositivo es demasiado antiguo (API $sdk; hace falta API $minSdk o superior). Fire TV: Fire OS 6 en adelante."
}

# --- instalar y abrir ---
Write-Host 'Instalando (puede tardar un minuto) ...'
$res = (Adb -s $target install -r -d $Apk) -join ' '
if ($res -notmatch 'Success') { throw "La instalación falló: $res" }
Write-Host 'Instalado.'
if (-not $NoLaunch) {
    Adb -s $target shell am start -n "$package/.MainActivity" | Out-Null
    Write-Host "Lumio abierto en $target."
}
