# IPTV Launcher

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
- Diseño moderno con tarjetas de cristal. El diseño anterior sigue disponible en la rama/etiqueta `design-v1-classic`.

## Pendiente

EPG (XMLTV), base de datos local (drift), favoritos, "continuar viendo", control parental, multi-pantalla, PiP nativo, selector de pistas en la UI, módulo freemium y PVR. El detalle está en [`CLAUDE.md`](CLAUDE.md).

## Instalar (usuarios)

No hace falta instalar nada más: cada paquete trae lo que necesita. Se generan en [Releases](../../releases) al publicar una versión (ver más abajo).

| Sistema | Paquete | Cómo instalar |
|---|---|---|
| Windows 10/11 | `IPTV-Launcher-windows.zip` | Descomprimir y doble clic en `Install.cmd`. Sin administrador; crea accesos directos en el Escritorio y el menú Inicio. |
| Linux | `IPTV-Launcher-linux-x64.tar.gz` | Descomprimir y ejecutar `./install.sh`. Instala solo las librerías que falten (libmpv, GTK, libsecret) con el gestor de paquetes (apt, dnf, pacman o zypper). |
| macOS | `IPTV-Launcher-macos.zip` | Descomprimir y arrastrar a Aplicaciones. App sin firmar: la primera vez, clic derecho → Abrir. |
| Android | `IPTV-Launcher-android.apk` | Abrir el APK en el dispositivo y permitir la instalación de orígenes desconocidos. |
| iOS | — | Requiere cuenta de desarrollador de Apple para firmar e instalar; no se distribuye aún. |

Solo el paquete de Windows se ha probado de verdad. La app arranca y pasa una prueba de humo en Windows, Linux, macOS y un simulador de iPhone (flujo `Plataformas`); los paquetes instalables de los demás sistemas los construye `.github/workflows/release.yml` y **aún no se han ejecutado**.

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
