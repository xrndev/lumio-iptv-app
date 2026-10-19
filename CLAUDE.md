# IPTV Launcher

Reproductor IPTV Flutter, una sola base de código para Android, iOS, Windows, macOS y Linux (+ modo TV/leanback en Android TV). Prioridades: arranque y búsqueda en milisegundos, listas de 50k+ canales sin jank, UI accesible (teclado / D-Pad / lector de pantalla).

## Estado actual

Verificado (Flutter 3.47.7 / Dart 3.13.5, instalado en `~\dev\flutter`, añadir su `bin` al PATH): `flutter analyze` sin incidencias, 4 tests en verde, benchmark M3U 50k canales = 367 ms / +11 MB RSS (JIT). `flutter build windows --debug` compila y el .exe arranca y se mantiene vivo (8 s). **No se ha probado reproducción real de streams ni la UI visualmente**, ni Android/iOS/macOS/Linux (sin Android SDK en esta máquina).

Diseño: "v2" moderno (tema violeta/cian, tarjetas de cristal `GlassCard`, sidebar flotante, chips de categoría, overlay de reproductor con volumen/mute/rueda/atajos Espacio·M·F·↑↓·Esc). El diseño anterior está respaldado en la rama y etiqueta `design-v1-classic` (`git checkout design-v1-classic` para volver). Tokens en `design_system/theme/app_theme.dart`; los controles viven en `features/player/presentation/player_overlay.dart` y se pasan como `controls` de `Video` para funcionar también en pantalla completa.

Persistencia: la fuente activa (`SavedSource`: URL M3U, ruta de archivo o cuenta Xtream) se guarda tras cargarla con éxito en almacenamiento cifrado del sistema (`flutter_secure_storage`, `core/storage/source_store.dart`) y se restaura sola en `PlaylistController.build()`. **Solo se borra con `PlaylistController.clear()`** (Ajustes → Eliminar fuente); una fuente nueva que falla no pisa la guardada, y si al arrancar falla (sin red) se conserva y se ofrece "Reintentar". Las listas M3U por URL se cachean en el directorio de datos de la app para uso sin red. No guardar contraseñas ni tokens en logs ni en `SavedSource.label`. En Windows el plugin exige el componente **C++ ATL** de Visual Studio Build Tools (`Microsoft.VisualStudio.Component.VC.ATL`).

Secciones: En vivo, Películas, Series (solo con cuenta Xtream; catálogos en `features/vod`), Buscar (global: canales + películas + series), Favoritos (pendiente), Ajustes. Reproducción de VOD/episodios: `openPlayer()` → `PlayerPage` (barra de progreso, ±10 s, pistas de audio/subtítulos). Comprobar el cliente contra un servidor real: `IPTV_XTREAM="host|user|pass" dart run tool/probe_xtream.dart` (las credenciales nunca van al repo). La cuenta de prueba del usuario permite 1 sola conexión: no lanzar dos streams a la vez.

Depuración del reproductor (solo `kDebugMode`): log de libmpv en `%TEMP%\iptv_player.log`; `IPTV_AUTOPLAY=<url>` reproduce al arrancar; `IPTV_MPV_OPTS="clave=valor;clave=valor"` aplica propiedades mpv sin recompilar; `IPTV_AUTOLOAD=<ruta .m3u>` + `IPTV_PLAY_NAME=<texto>` cargan una lista y reproducen un canal al arrancar (en `HomePage`); `IPTV_XTREAM="host|user|pass"` y `IPTV_TAB=<n>` idem para Xtream/pestaña. **Esos ganchos guardan la fuente como cualquier carga**: usar `IPTV_NO_PERSIST=1` en pruebas para no pisar la fuente guardada del usuario. `%TEMP%\iptv_source.log` registra qué fuente se restauró. Lección: el HLS maestro de RTVE (renditions de audio+subtítulos) se quedaba en buffering hasta fijar `demuxer-lavf-o=allowed_segment_extensions=ALL` en `PlayerEngine`. Muchas URLs de listas públicas están caídas: comprobar con `curl` antes de culpar al reproductor.

Fuentes: M3U por URL, archivo local (`file_picker`) y Xtream Codes (Live; `XtreamClient`, probado solo con tests unitarios, no contra un servidor real). Sin persistencia aún: al cerrar la app se pierde la fuente.

Requisito en Windows: **Modo desarrollador** activado (ya lo está); sin él `flutter pub get` falla con "Building with plugins requires symlink support".

Implementado: parser M3U (Isolate, streaming), motor de reproducción `media_kit`, shell adaptativo (compact/medium/expanded), tema, canal nativo PiP (stub Dart), tests del parser y benchmark.
Pendiente: Xtream Codes, EPG XMLTV, base de datos (drift), favoritos, control parental, multi-screen, catch-up, VOD/TMDB, premium/licencias, PVR, sync.

## Comandos

```powershell
./scripts/setup.ps1                       # skills + carpetas de plataforma (una vez)
flutter pub get
flutter analyze
flutter test
flutter run -d windows                    # o android / ios / macos / linux / chrome
dart run tool/benchmark_m3u.dart 50000    # benchmark parser (tiempo + RSS)
```

## Arquitectura

```
lib/
  main.dart / app.dart        # bootstrap (MediaKit.ensureInitialized), MaterialApp + tema
  core/                       # sin dependencias de UI
    models/                   # Channel, M3uPlaylist (inmutables, sendable entre Isolates)
    parsing/                  # m3u_parser.dart  (+ xmltv_parser.dart pendiente)
    network/                  # Dio, descarga a disco en streaming
    storage/                  # drift (pendiente)
  features/                   # una carpeta por feature: data/ domain/ presentation/
    home/                     # shell adaptativo + paneles
    player/                   # PlayerEngine (media_kit) + PlayerView
    playlists/                # carga de fuentes, estado Riverpod
  design_system/              # tema, tokens, widgets reutilizables, adaptive/
    adaptive/                 # ScreenType + breakpoints + AdaptiveScaffold
  platform_channels/          # MethodChannels nativos (PiP, TV detection)
test/  tool/  scripts/  .claude/agents/
```

Reglas de capas: `core` no importa `features` ni `design_system`. `features/*` pueden importar `core` y `design_system`, y no otros features, salvo `features/home`, que es la capa de composición y sí los combina. Los canales de plataforma solo se usan desde `features/*/data`.

## Convenciones

- Estado: Riverpod (sin codegen por ahora). Providers junto a su feature.
- **Nunca** parsear listas/EPG en el isolate de UI: usar `M3uParser.parseFile` (Isolate) o `Isolate.run`. Descargar listas a disco en streaming, no a memoria.
- Los modelos que cruzan Isolates deben ser `final` y sin closures. Deduplicar strings repetidos (grupos) con interning.
- Breakpoints (Material window size classes): compact < 600dp, medium 600–839dp, expanded ≥ 840dp. Siempre vía `ScreenType.of(context)`; no usar `MediaQuery.size.width` suelto. Modo TV se detecta aparte (`platform_channels`), no por ancho.
- Accesibilidad obligatoria: zonas táctiles ≥ 48dp, `Semantics` en controles del reproductor, foco visible, todo operable con teclado/D-Pad, respetar `MediaQuery.textScaler`.
- Reproductor: propiedades mpv vía `NativePlayer.setProperty` (`video-aspect-override`, `audio-delay`, `panscan`) solo en `PlayerEngine`.
- Tests: todo parser nuevo con test unitario + caso malformado. UI adaptativa: widget tests a 400, 700 y 1200dp de ancho.

## Agentes y skills del proyecto

Skills instaladas (`.claude/skills`): `design-mobile-apps` (orientada a React Native: usar solo como guía de principios), `mobile-android-design` (Material 3, navegación adaptativa), `ui-taste`, `ios-design`. Reinstalar con `scripts/setup.ps1`.

Agentes (`.claude/agents/`): `iptv-stream-tester` (validar streams con ffprobe/mpv), `m3u-epg-benchmarker` (rendimiento de parsers), `adaptive-layout-auditor` (breakpoints y accesibilidad). Invocarlos tras tocar player, parsers o layout respectivamente.

## Freemium (diseño, aún sin implementar)

Módulo desacoplado `features/entitlements` con interfaz `EntitlementsRepository` (`Stream<Set<Feature>>`). Implementaciones: RevenueCat (iOS/Android), LemonSqueezy/Stripe (desktop). La UI solo consulta `Feature`, nunca el proveedor. Free: 1 lista, sin multi-screen/PVR/offline/sync. Premium: ver especificación original del producto.

## Seguridad / legal

La app no incluye canales ni listas. No hardcodear credenciales Xtream/TMDB: usar almacenamiento seguro (`flutter_secure_storage`) y `--dart-define` para claves de API.
