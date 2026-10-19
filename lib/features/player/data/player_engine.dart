import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/models/channel.dart';

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

/// Envuelve media_kit (libmpv). Es el único sitio donde se tocan propiedades mpv.
class PlayerEngine {
  PlayerEngine()
      : player = Player(
          configuration: const PlayerConfiguration(
            // Buffer de demuxer ampliado para IPTV con jitter.
            bufferSize: 32 * 1024 * 1024,
            title: 'IPTV Launcher',
            logLevel: MPVLogLevel.v,
          ),
        ) {
    if (kDebugMode) _attachDebugLog();
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
    void out(String s) => file.writeAsStringSync('$s\n', mode: FileMode.append);
    player.stream.log.listen((l) => out('[${l.level}] ${l.prefix}: ${l.text.trimRight()}'));
    player.stream.error.listen((e) => out('[ERROR] $e'));
    player.stream.width.listen((w) => out('[state] width=$w height=${player.state.height}'));
    player.stream.tracks.listen((t) => out(
        '[tracks] video=${t.video.map((x) => x.codec)} audio=${t.audio.map((x) => x.codec)}'));
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

  Future<void> play(Channel channel) async {
    await player.open(
      Media(channel.url, httpHeaders: channel.httpHeaders.isEmpty ? null : channel.httpHeaders),
      play: true,
    );
  }

  Future<void> togglePlay() => player.playOrPause();

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

  Future<void> dispose() => player.dispose();
}
