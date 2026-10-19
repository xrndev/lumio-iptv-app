# IPTV Launcher

Reproductor IPTV hecho con Flutter: una sola base de código para Android, iOS, Windows, macOS y Linux. Pensado para listas grandes (50.000+ canales) sin bloquear la interfaz.

> **Estado: prototipo temprano.** Solo se ha compilado y probado en Windows. No incluye canales ni listas: hay que aportar tu propia fuente.

## Qué funciona hoy

- Fuentes: **M3U por URL**, **archivo local** y **Xtream Codes** (canales en vivo, categorías, catch-up y estado de la cuenta).
- Parser M3U en streaming dentro de un Isolate: 50.000 canales en ~370 ms y ~11 MB de memoria (modo JIT).
- Reproducción con [`media_kit`](https://github.com/media-kit/media-kit) (libmpv) y aceleración por hardware. Probado con HLS H.264.
- Interfaz adaptativa según el ancho de ventana: barra inferior (< 600 dp), rail lateral (600–839 dp) y sidebar con vista dividida lista + reproductor (≥ 840 dp).
- Búsqueda de canales, selector de relación de aspecto y logos.

## Pendiente

EPG (XMLTV), base de datos local (drift), persistencia de fuentes, favoritos, control parental, VOD y series (TMDB), multi-pantalla, PiP nativo, selector de pistas en la UI, módulo freemium y PVR. El detalle está en [`CLAUDE.md`](CLAUDE.md).

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) estable (probado con 3.47.7 / Dart 3.13).
- Windows: **Modo desarrollador** activado (`start ms-settings:developers`), necesario para los symlinks de los plugins, y Visual Studio con la carga de trabajo de C++.
- Node.js solo si quieres reinstalar las skills de diseño.

## Puesta en marcha

```powershell
./scripts/setup.ps1        # genera carpetas de plataforma que falten + flutter pub get
flutter run -d windows     # o android / ios / macos / linux
```

En macOS/Linux usa `scripts/setup.sh`.

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
