<p align="center">
  <img src="assets/branding/lumio_icon_round.png" width="112" alt="Logo de Lumio">
</p>

<h1 align="center">Lumio</h1>

<p align="center">
  Reproductor IPTV hecho con Flutter: una sola base de código para Android, Android TV / Fire TV, iOS, Windows, macOS y Linux.<br>
  Pensado para listas de 50.000+ canales sin bloquear la interfaz.
</p>

<p align="center">
  <a href="https://buymeacoffee.com/xrndev"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-xrndev-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy me a coffee"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/licencia-GPL--3.0-blue" alt="Licencia GPL-3.0"></a>
</p>

> **Estado: prototipo temprano.** Probado a mano en Windows y en un Fire TV Stick 4K Max; el resto de plataformas solo con pruebas automáticas. Lumio no incluye canales ni listas: aporta tu propia fuente.

## Funciones

- **Fuentes:** M3U por URL, archivo local y Xtream Codes (en vivo, películas, series, catch-up). La fuente se guarda cifrada y se restaura sola.
- **Rápido:** 50.000 canales parseados en ~370 ms; listas cacheadas en disco para arrancar sin red.
- **Reproductor** (`media_kit`/libmpv, decodificación por hardware, 4K/HEVC) con recuperación automática de errores, pistas de audio/subtítulos, ±10 s y atajos de teclado.
- **Biblioteca:** favoritos, recientes y continuar viendo, transferibles entre dispositivos con un código. Búsqueda global y guía "Ahora / Después".
- **Chromecast** y **modo TV** (mando de Fire TV / Android TV, foco con D-Pad).
- Interfaz adaptativa (móvil, tablet, escritorio, TV), tema oscuro y accesible (teclado, lector de pantalla).

Pendiente: sincronización automática, EPG XMLTV completa, control parental, multi-pantalla, PiP nativo. Detalle y estado de verificación en [`CLAUDE.md`](CLAUDE.md).

## Instalar

Descarga el paquete de la última versión en [Releases](../../releases):

| Sistema | Paquete | Instalación |
|---|---|---|
| Windows 10/11 | `Lumio-windows.zip` | Descomprimir y ejecutar `Install.cmd` (sin administrador). |
| Linux | `Lumio-linux-x64.tar.gz` | Descomprimir y ejecutar `./install.sh`. |
| macOS | `Lumio-macos.zip` | Arrastrar a Aplicaciones; sin firmar: clic derecho → Abrir. |
| Android / Fire TV | `Lumio-android.apk` | Instalar el APK (orígenes desconocidos). Fire OS 6+; en Fire TV: `./scripts/android/install-device.ps1 -Ip <IP>` con la depuración ADB activada. |
| iOS | — | Aún no se distribuye (requiere firma de Apple). |

## Desarrollo

```powershell
./scripts/setup.ps1     # Windows  (./scripts/setup.sh en macOS / Linux): instala Flutter y dependencias
flutter pub get
flutter run -d windows  # o linux / macos / android
flutter analyze && flutter test
```

Paquetes locales: `./scripts/package-windows.ps1 -Install` (Windows) o `./scripts/package.sh` (Linux/macOS). Arquitectura, capas y convenciones: [`CLAUDE.md`](CLAUDE.md).

## Cómo contribuir

1. **Haz un fork** del repositorio y clónalo.
2. **Crea una rama** desde `main` con un nombre descriptivo:
   ```bash
   git checkout main && git pull
   git checkout -b feat/mi-cambio      # o fix/..., docs/...
   ```
3. **Haz tus cambios** siguiendo las convenciones de [`CLAUDE.md`](CLAUDE.md) (capas, accesibilidad, un test por parser nuevo). Antes de subir:
   ```bash
   flutter analyze && flutter test
   ```
4. **Commits pequeños y claros**, en imperativo (`Corrige el foco en la barra lateral`).
5. **Sube la rama y abre una Pull Request** hacia `main`:
   ```bash
   git push -u origin feat/mi-cambio
   ```
   Explica qué cambia y por qué, y en qué plataforma lo probaste. Si toca la interfaz, añade una captura.
6. La rama `main` está **protegida**: no se admiten pushes directos, y la PR debe pasar el check `calidad` (análisis + tests) antes de fusionarse.

Para errores o ideas, abre primero un *issue*. Al contribuir aceptas que tu aportación se publique bajo la licencia GPL-3.0.

## Apoyar el proyecto

Si Lumio te resulta útil, puedes invitarme a un café:

<a href="https://buymeacoffee.com/xrndev"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=xrndev&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy me a coffee" height="48"></a>

## Aviso legal

Lumio es solo un reproductor: no proporciona, aloja ni recomienda contenido. Eres responsable de usar únicamente fuentes sobre las que tengas derecho.
