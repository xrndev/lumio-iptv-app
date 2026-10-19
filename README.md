<p align="center">
  <img src="assets/branding/lumio_icon_round.png" width="128" alt="Logo de Lumio">
</p>

# Lumio

Reproductor IPTV hecho con Flutter: una sola base de código para Android, iOS, Windows, macOS y Linux. Pensado para listas grandes (50.000+ canales) sin bloquear la interfaz.

> **Estado: prototipo temprano.** Solo se ha compilado y probado en Windows. No incluye canales ni listas: hay que aportar tu propia fuente.

## Qué funciona hoy

- Fuentes: **M3U por URL**, **archivo local** y **Xtream Codes** (canales en vivo, categorías, catch-up y estado de la cuenta).
- Parser M3U en streaming dentro de un Isolate: 50.000 canales en ~370 ms y ~11 MB de memoria (modo JIT).
- Reproducción con [`media_kit`](https://github.com/media-kit/media-kit) (libmpv) y aceleración por hardware. Probado con HLS H.264.
- Interfaz adaptativa según el ancho de ventana: barra inferior (< 600 dp), rail lateral (600–839 dp) y sidebar con vista dividida lista + reproductor (≥ 840 dp).
- Búsqueda de canales, filtro por categorías, selector de relación de aspecto y logos.
- **Películas y series** (cuentas Xtream): rejilla de pósteres con categorías y búsqueda, fichas con sinopsis, temporadas y episodios, barra de progreso, ±10 s y selector de audio/subtítulos.
- **Búsqueda global** de canales, películas y series desde el menú.
- **La fuente se guarda** y se carga sola al abrir la app (credenciales cifradas por el sistema); solo se elimina desde Ajustes.
- Controles del reproductor: volumen (slider, silencio, rueda del ratón), pantalla completa y atajos de teclado: `Espacio` pausa, `M` silencio, `↑`/`↓` volumen, `F` pantalla completa, `Esc` salir.
- **Favoritos** (⭐ en canales, pósteres, fichas y reproductor), **canales recientes** y **continuar viendo** (películas y episodios se reanudan donde los dejaste; barra de progreso y marca de visto). Se guardan por cuenta y se pueden **pasar a otro dispositivo** con un código (Favoritos → ⇄): se fusionan sin perder nada.
- **Guía de programación**: "Ahora / Después" con barra de progreso en el reproductor (si tu proveedor la ofrece).
- **Chromecast**: emite el canal o la película a un Chromecast desde el reproductor (móvil, tablet y escritorio).
- Arranque rápido: las listas de la cuenta se guardan en disco (6 h) y se usan sin red si hace falta; logos y pósteres también se cachean en disco.
- Nombres de canal limpios (sin `ES|`, símbolos ni etiquetas de calidad; la calidad sale como insignia), búsqueda sin distinguir tildes y avisos de caducidad de la cuenta.
- Diseño moderno con tarjetas de cristal. El diseño anterior sigue disponible en la rama/etiqueta `design-v1-classic`.

## Pendiente

Sincronización automática entre dispositivos (hoy: código manual; necesita un servidor), EPG completa (XMLTV, parrilla), base de datos local (drift), control parental, multi-pantalla, PiP nativo, selector de pistas en la UI, módulo freemium y PVR. El detalle está en [`CLAUDE.md`](CLAUDE.md).

## Instalar (usuarios)

No hace falta instalar nada más: cada paquete trae lo que necesita. Se generan en [Releases](../../releases) al publicar una versión (ver más abajo).

| Sistema | Paquete | Cómo instalar |
|---|---|---|
| Windows 10/11 | `Lumio-windows.zip` | Descomprimir y doble clic en `Install.cmd`. Sin administrador; crea accesos directos en el Escritorio y el menú Inicio. |
| Linux | `Lumio-linux-x64.tar.gz` | Descomprimir y ejecutar `./install.sh`. Instala solo las librerías que falten (libmpv, GTK, libsecret) con el gestor de paquetes (apt, dnf, pacman o zypper). |
| macOS | `Lumio-macos.zip` | Descomprimir y arrastrar a Aplicaciones. App sin firmar: la primera vez, clic derecho → Abrir. |
| Android | `Lumio-android.apk` | Abrir el APK en el dispositivo y permitir la instalación de orígenes desconocidos. |
| Fire TV / Fire Stick | `Lumio-android.apk` (el mismo) | Ver "Fire TV" más abajo. Fire OS 6 o superior. |
| iOS | — | Requiere cuenta de desarrollador de Apple para firmar e instalar; no se distribuye aún. |

### Fire TV / Fire Stick

Lumio funciona con el mando de Amazon: flechas y OK para navegar, **OK** pausa y reanuda, **⏪ ⏩** saltan 10 s en películas y series, **⏯** pausa y **Atrás** vuelve. El texto es algo mayor en TV y no se ofrece el selector de archivos (en TV no hay gestor de archivos): añade la lista por URL o con una cuenta Xtream Codes.

Instalar desde el PC, con el Fire TV y el PC en la misma red:

1. En el Fire TV: Ajustes → Mi Fire TV → Opciones para desarrolladores → activa **Depuración ADB** y **Aplicaciones de orígenes desconocidos**. (Si no sale ese menú: Ajustes → Mi Fire TV → Acerca de, y pulsa 7 veces sobre el nombre del dispositivo.)
2. Apunta su IP: Ajustes → Mi Fire TV → Acerca de → Red.
3. Ejecuta `./scripts/android/install-device.ps1 -Ip <IP del Fire TV>` y acepta el aviso de depuración que sale en el televisor.

Requisitos: Fire OS 6 (Android 7.1) o superior, es decir, Fire TV Stick de 3.ª generación, Lite, 4K, 4K Max y Fire TV Cube recientes. Los Fire Stick de 1.ª y 2.ª generación (Fire OS 5) no son compatibles. **Sin probar en un Fire Stick real** (ver `CLAUDE.md`).

Qué se ha verificado de verdad:

- **Windows:** instalado y usado a mano.
- **Windows, Linux, macOS y simulador de iPhone:** la app arranca y pasa una prueba de humo (menú, foco con teclado/mando, carga de lista, reproductor), y el guardado cifrado de la fuente funciona en los cuatro con el almacén real de cada sistema.
- **Linux:** además, el paquete se instala con `install.sh` y la app instalada arranca.
- **Todos los paquetes** (Windows, Linux, macOS, Android) se construyen con `.github/workflows/release.yml`.

Sin verificar: reproducción de vídeo real y mando físico en Linux, macOS, iOS y Android, y la app instalada en un dispositivo Android real.

Las pruebas de Linux, macOS e iOS no corren solas (los ejecutores de macOS cuestan 10x en minutos): se lanzan a mano desde Actions → Plataformas → Run workflow.

## Desarrollar

Un solo comando prepara el entorno e instala lo que falte (Git, Flutter, Modo desarrollador y C++ ATL en Windows; compiladores y librerías en Linux; herramientas de Xcode en macOS):

```powershell
./scripts/setup.ps1        # Windows (pedirá permiso de administrador solo si hace falta)
./scripts/setup.sh         # macOS / Linux
flutter run -d windows     # o linux / macos / android
```

Generar un paquete instalable en tu sistema:

```powershell
./scripts/package-windows.ps1 -Install   # Windows: compila, empaqueta e instala con acceso directo
./scripts/package.sh                     # Linux / macOS
```

Publicar una versión para todos los sistemas: `git tag v0.1.0 && git push origin v0.1.0`.

```powershell
flutter analyze
flutter test
dart run tool/benchmark_m3u.dart 50000   # benchmark del parser
```

## Estructura

```
lib/
  core/               # modelos, parser M3U, cliente Xtream, descargas
  features/           # home, player, playlists
  design_system/      # tema y layout adaptativo (ScreenType, AdaptiveScaffold)
  platform_channels/  # PiP y detección de TV (lado nativo pendiente)
test/  tool/  scripts/  .claude/agents/
```

Las reglas de capas y las convenciones están en [`CLAUDE.md`](CLAUDE.md).

## Agentes de Claude Code

En `.claude/agents/` hay tres agentes de apoyo: `iptv-stream-tester` (validar streams), `m3u-epg-benchmarker` (rendimiento de parsers) y `adaptive-layout-auditor` (responsive y accesibilidad).

## Depuración del reproductor

Solo en modo debug: el log de libmpv se escribe en `%TEMP%\iptv_player.log`, `IPTV_AUTOPLAY=<url>` reproduce una URL al arrancar e `IPTV_MPV_OPTS="clave=valor;clave=valor"` aplica propiedades de mpv sin recompilar.

## Aviso legal

Esta aplicación es solo un reproductor. No proporciona, aloja ni recomienda contenido. Eres responsable de usar únicamente fuentes sobre las que tengas derecho.
