import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/models/channel.dart';
import 'issue_text.dart';
import 'playback_recovery.dart';

enum AspectMode {
  auto('Auto', null, 0),
  r16x9('16:9', '16:9', 0),
  r4x3('4:3', '4:3', 0),
  zoom('Zoom', null, 1),
  stretch('Estirar', '-1', 0);

  const AspectMode(this.label, this.mpvAspect, this.panscan);
  final String label;

  /// Valor de `video-aspect-override` (`-1` = por defecto del vídeo).
  final String? mpvAspect;

  /// Valor de `panscan` (1 = recorta para llenar la pantalla).
  final double panscan;
}

enum PlaybackPhase { idle, loading, retrying, playing, failed }

/// Mensaje de estado; la UI lo traduce.
enum PlaybackNotice { none, reconnecting, tryingFormat, openFailed }

class PlaybackStatus {
  const PlaybackStatus(this.phase, [this.notice = PlaybackNotice.none, this.detail = '']);
  static const idle = PlaybackStatus(PlaybackPhase.idle);
  static const playing = PlaybackStatus(PlaybackPhase.playing);

  final PlaybackPhase phase;
  final PlaybackNotice notice;

  /// Motivo técnico (ya sin credenciales) para diagnosticar; vacío si no se conoce.
  final String detail;
}

/// Envuelve media_kit (libmpv). Es el único sitio donde se tocan propiedades mpv.
class PlayerEngine {
  PlayerEngine()
      : player = Player(
          configuration: PlayerConfiguration(
            // Buffer de demuxer ampliado: 4K/HEVC a 15–25 Mbps necesita ~20–30 s de margen en
            // escritorio. En Android (móviles y, sobre todo, Fire Stick / Android TV con 1–2 GB
            // de RAM compartida con el sistema) se reduce a la mitad para no ser cerrada por
            // falta de memoria; sigue dando ~10–15 s a 15–25 Mbps.
            bufferSize: (Platform.isAndroid ? 32 : 64) * 1024 * 1024,
            title: 'Lumio',
            logLevel: kDebugMode ? MPVLogLevel.v : MPVLogLevel.warn,
          ),
        ) {
    if (kDebugMode) _attachDebugLog();
    _listenPlayback();
    video = VideoController(
      player,
      configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true),
    );
    _applyLiveDefaults();
  }

  final Player player;
  late final VideoController video;

  NativePlayer get _mpv => player.platform as NativePlayer;

  /// Solo debug: vuelca log/errores de libmpv a `%TEMP%/iptv_player.log`.
  void _attachDebugLog() {
    final file = File('${Directory.systemTemp.path}/iptv_player.log')
      ..writeAsStringSync('');
    void out(String s) => file.writeAsStringSync(
        '${DateTime.now().toIso8601String().substring(11, 23)} $s\n',
        mode: FileMode.append);
    player.stream.log.listen((l) => out('[${l.level}] ${l.prefix}: ${l.text.trimRight()}'));
    player.stream.error.listen((e) => out('[ERROR] $e'));
    player.stream.width.listen((w) => out('[state] width=$w height=${player.state.height}'));
    player.stream.tracks.listen((t) => out(
        '[tracks] video=${t.video.map((x) => x.codec)} audio=${t.audio.map((x) => x.codec)}'));
    // Métricas del decodificador cada 4 s (diagnóstico de 4K/HEVC).
    Timer.periodic(const Duration(seconds: 4), (_) async {
      Future<String> p(String k) async {
        try {
          return await _mpv.getProperty(k);
        } catch (_) {
          return '?';
        }
      }

      out('[stats] codec=${await p('video-codec')} hwdec=${await p('hwdec-current')} '
          'fmt=${await p('video-params/pixelformat')} size=${await p('video-params/w')}x${await p('video-params/h')} '
          'fps=${await p('container-fps')} dec_drop=${await p('decoder-frame-drop-count')} '
          'vo_drop=${await p('frame-drop-count')} cache_s=${await p('demuxer-cache-duration')} '
          'paused_cache=${await p('paused-for-cache')} speed=${await p('cache-speed')}');
    });
    player.stream.playing.listen((p) => out('[state] playing=$p'));
    player.stream.buffering.listen((b) => out('[state] buffering=$b'));
  }

  Future<void> _applyLiveDefaults() async {
    await _mpv.setProperty('hwdec', 'auto-safe');
    await _mpv.setProperty('cache', 'yes');
    await _mpv.setProperty('demuxer-readahead-secs', '10');
    // Sin esta opción el HLS maestro de RTVE (renditions de audio+subtítulos)
    // se queda en "buffering" sin pedir vídeo; también admite segmentos sin extensión.
    await _mpv.setProperty('demuxer-lavf-o', 'allowed_segment_extensions=ALL');
    // Solo debug: IPTV_MPV_OPTS="clave=valor;clave=valor" para experimentar.
    final extra = kDebugMode ? Platform.environment['IPTV_MPV_OPTS'] : null;
    for (final kv in (extra ?? '').split(';').where((s) => s.contains('='))) {
      final i = kv.indexOf('=');
      await _mpv.setProperty(kv.substring(0, i), kv.substring(i + 1));
    }
  }

  // --- Apertura con recuperación -------------------------------------------
  /// Estado de la apertura actual, para que la UI muestre "Reconectando…" o el error.
  final status = ValueNotifier<PlaybackStatus>(PlaybackStatus.idle);

  Channel? _channel;
  PlaybackRecovery? _recovery;
  String? _activeUrl;
  int _generation = 0; // invalida errores/temporizadores de aperturas anteriores
  Timer? _watchdog;
  final _subs = <StreamSubscription<Object?>>[];

  String? _lastIssue; // última línea del registro/errores útil para explicar un fallo

  void _listenPlayback() {
    _subs.add(player.stream.error.listen((e) {
      if (isInterestingIssue(e)) _lastIssue = e;
      _onError(e);
    }));
    _subs.add(player.stream.log.listen((l) {
      if ((l.level == 'error' || l.level == 'warn') && isInterestingIssue(l.text)) {
        _lastIssue = l.text;
      }
    }));
    // Primera imagen (o audio, en radios) = la apertura ha tenido éxito.
    _subs.add(player.stream.width.listen((w) {
      if ((w ?? 0) > 0) _onStarted();
    }));
    _subs.add(player.stream.position.listen((p) {
      if (p > Duration.zero) _onStarted();
    }));
  }

  void _onStarted() {
    if (_channel == null || status.value.phase == PlaybackPhase.playing) return;
    _watchdog?.cancel();
    status.value = PlaybackStatus.playing;
  }

  void _onError(String message) {
    final url = _activeUrl;
    if (_channel == null || url == null) return;
    // Un error de una apertura anterior (otra URL) no debe afectar a la actual.
    if (message.contains('Failed to open') && !message.contains(url)) return;
    unawaited(_recover(_generation));
  }

  Future<void> _recover(int generation) async {
    if (generation != _generation) return;
    _watchdog?.cancel();
    final channel = _channel;
    final recovery = _recovery;
    if (channel == null || recovery == null) return;

    switch (recovery.onFailure()) {
      case RecoveryAction.retrySame:
        status.value = const PlaybackStatus(PlaybackPhase.retrying, PlaybackNotice.reconnecting);
        await Future<void>.delayed(PlaybackRecovery.retryDelay);
        if (generation == _generation) await _open(channel.url, channel, generation);
      case RecoveryAction.tryAlternate:
        status.value = const PlaybackStatus(PlaybackPhase.retrying, PlaybackNotice.tryingFormat);
        if (generation == _generation) await _open(channel.altUrl!, channel, generation);
      case RecoveryAction.giveUp:
        status.value = PlaybackStatus(
          PlaybackPhase.failed,
          PlaybackNotice.openFailed,
          sanitizeIssue(_lastIssue ?? ''),
        );
    }
  }

  Future<void> _open(String url, Channel channel, int generation) async {
    _activeUrl = url;
    await player.open(
      Media(
        url,
        httpHeaders: channel.httpHeaders.isEmpty ? null : channel.httpHeaders,
        start: _startAt, // reanudar donde se dejó (solo películas y episodios)
      ),
      play: true,
    );
    _watchdog?.cancel();
    _watchdog = Timer(PlaybackRecovery.watchdog, () => unawaited(_recover(generation)));
  }

  Duration? _startAt;

  /// Abre [channel]; con [startAt] empieza en ese punto (reanudar película o episodio).
  Future<void> play(Channel channel, {Duration? startAt}) async {
    final hadStream = _activeUrl != null && status.value.phase != PlaybackPhase.idle;
    final generation = ++_generation;
    _channel = channel;
    _startAt = startAt;
    _recovery = PlaybackRecovery(hasAlternate: channel.altUrl != null);
    _lastIssue = null;
    status.value = const PlaybackStatus(PlaybackPhase.loading);
    if (hadStream) {
      // Con una sola conexión permitida, soltar la anterior antes de pedir la nueva.
      await player.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (generation != _generation) return;
    }
    await _open(channel.url, channel, generation);
  }

  /// Reintenta el canal actual desde cero (botón "Reintentar").
  Future<void> retry() async {
    final c = _channel;
    if (c != null) await play(c, startAt: _startAt);
  }

  Future<void> togglePlay() => player.playOrPause();
  Future<void> resume() => player.play();
  Future<void> pause() => player.pause();

  Future<void> stop() async {
    _generation++;
    _watchdog?.cancel();
    _channel = null;
    _activeUrl = null;
    status.value = PlaybackStatus.idle;
    await player.stop();
  }

  // --- Posición (VOD / series) ----------------------------------------------
  Stream<Duration> get positionStream => player.stream.position;
  Stream<Duration> get durationStream => player.stream.duration;
  Duration get position => player.state.position;
  Duration get duration => player.state.duration;

  Future<void> seek(Duration to) {
    final max = duration;
    final clamped = to < Duration.zero ? Duration.zero : (max > Duration.zero && to > max ? max : to);
    return player.seek(clamped);
  }

  Future<void> seekBy(Duration delta) => seek(position + delta);

  // --- Volumen (0–100) ------------------------------------------------------
  double _preMuteVolume = 100;
  double get volume => player.state.volume;
  Stream<double> get volumeStream => player.stream.volume;
  bool get isMuted => player.state.volume == 0;

  Future<void> setVolume(double percent) => player.setVolume(percent.clamp(0, 100).toDouble());
  Future<void> changeVolume(double delta) => setVolume(volume + delta);

  Future<void> toggleMute() async {
    if (isMuted) {
      await setVolume(_preMuteVolume > 0 ? _preMuteVolume : 50);
    } else {
      _preMuteVolume = volume;
      await setVolume(0);
    }
  }

  // --- Pistas ---------------------------------------------------------------
  Stream<Tracks> get tracksStream => player.stream.tracks;
  Future<void> setAudioTrack(AudioTrack t) => player.setAudioTrack(t);
  Future<void> setSubtitleTrack(SubtitleTrack t) => player.setSubtitleTrack(t);

  /// Subtítulo externo (SRT/ASS/VTT) por URL o ruta.
  Future<void> loadExternalSubtitle(String uriOrPath, {String? title}) =>
      player.setSubtitleTrack(SubtitleTrack.uri(uriOrPath, title: title));

  // --- Imagen / sincronía ---------------------------------------------------
  Future<void> setAspect(AspectMode mode) async {
    await _mpv.setProperty('video-aspect-override', mode.mpvAspect ?? '-1');
    await _mpv.setProperty('panscan', mode.panscan.toString());
  }

  /// Desfase de audio en segundos (positivo = retrasa el audio).
  Future<void> setAudioDelay(double seconds) =>
      _mpv.setProperty('audio-delay', seconds.toStringAsFixed(2));

  Future<void> dispose() async {
    _watchdog?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    status.dispose();
    await player.dispose();
  }
}
