import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' show AudioTrack, SubtitleTrack, Tracks;
import 'package:media_kit_video/media_kit_video.dart';

import '../../../design_system/theme/app_theme.dart';
import '../data/player_engine.dart';
import '../player_providers.dart';
import 'remote_keys.dart';

/// Controles superpuestos: play/pausa, volumen (slider, mute, rueda, ↑/↓),
/// progreso y ±10 s (solo VOD), pistas de audio/subtítulos, relación de aspecto
/// y pantalla completa. Se ocultan solos tras 3 s.
class PlayerOverlay extends ConsumerStatefulWidget {
  const PlayerOverlay({super.key, required this.state, this.onBack});

  final VideoState state;
  final VoidCallback? onBack;

  @override
  ConsumerState<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends ConsumerState<PlayerOverlay> {
  final _focus = FocusNode();
  Timer? _hideTimer;
  Timer? _hudTimer;
  bool _visible = true;
  String? _hud;

  PlayerEngine get _engine => ref.read(playerEngineProvider);
  bool get _isLive => ref.read(currentChannelProvider)?.isLive ?? true;

  @override
  void dispose() {
    _focus.dispose();
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    super.dispose();
  }

  void _poke() {
    if (!_visible) setState(() => _visible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _engine.player.state.playing) setState(() => _visible = false);
    });
  }

  void _showHud(String text) {
    setState(() => _hud = text);
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _hud = null);
    });
  }

  Future<void> _changeVolume(double delta) async {
    await _engine.changeVolume(delta);
    _showHud('Volumen ${_engine.volume.round()}%');
    _poke();
  }

  Future<void> _toggleMute() async {
    await _engine.toggleMute();
    _showHud(_engine.isMuted ? 'Silenciado' : 'Volumen ${_engine.volume.round()}%');
    _poke();
  }

  Future<void> _skip(int seconds) async {
    await _engine.seekBy(Duration(seconds: seconds));
    _showHud(seconds > 0 ? '+${seconds}s' : '${seconds}s');
    _poke();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final wasHidden = !_visible;
    if (e is KeyDownEvent) _poke(); // cualquier tecla del mando muestra los controles
    // Teclas multimedia del mando (Fire TV: ⏪ ⏯ ⏩). Funcionan estén donde esté el foco.
    final media = mapMediaKey(k);
    if (media != RemoteAction.none) {
      switch (media) {
        case RemoteAction.playPause:
          if (e is KeyDownEvent) _engine.togglePlay();
        case RemoteAction.play:
          if (e is KeyDownEvent) _engine.resume();
        case RemoteAction.pause:
          if (e is KeyDownEvent) _engine.pause();
        case RemoteAction.seekBack:
          if (!_isLive) _skip(-remoteSeekSeconds);
        case RemoteAction.seekForward:
          if (!_isLive) _skip(remoteSeekSeconds);
        case RemoteAction.none:
          break;
      }
      return KeyEventResult.handled;
    }
    // OK / Enter del mando: pausa o reanuda (la primera pulsación solo muestra los controles).
    // Solo con el foco en el propio overlay: si lo tiene un botón, OK debe activarlo.
    if (e is KeyDownEvent &&
        node.hasPrimaryFocus &&
        (k == LogicalKeyboardKey.select ||
            k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter ||
            k == LogicalKeyboardKey.gameButtonA ||
            k == LogicalKeyboardKey.mediaPlayPause)) {
      if (!wasHidden || k == LogicalKeyboardKey.mediaPlayPause) _engine.togglePlay();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp && node.hasPrimaryFocus) {
      _changeVolume(5);
    } else if (k == LogicalKeyboardKey.arrowDown && node.hasPrimaryFocus) {
      _changeVolume(-5);
    } else if (k == LogicalKeyboardKey.arrowRight && !_isLive) {
      _skip(10);
    } else if (k == LogicalKeyboardKey.arrowLeft && !_isLive) {
      _skip(-10);
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.keyM) {
      _toggleMute();
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.space) {
      _engine.togglePlay();
      _poke();
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.keyF) {
      widget.state.toggleFullscreen();
    } else if (e is KeyDownEvent && k == LogicalKeyboardKey.escape && widget.state.isFullscreen()) {
      widget.state.exitFullscreen();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(playerEngineProvider);
    final channel = ref.watch(currentChannelProvider);
    final live = channel?.isLive ?? true;

    return Focus(
      focusNode: _focus,
      autofocus: widget.onBack != null, // en pantalla dedicada, atajos desde el inicio
      onKeyEvent: _onKey,
      child: Listener(
        onPointerSignal: (s) {
          if (s is PointerScrollEvent) _changeVolume(s.scrollDelta.dy < 0 ? 5 : -5);
        },
        child: MouseRegion(
          onHover: (_) => _poke(),
          cursor: _visible ? MouseCursor.defer : SystemMouseCursors.none,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _focus.requestFocus();
              _poke();
            },
            onDoubleTap: widget.state.toggleFullscreen,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _Fade(
                    visible: _visible,
                    child: _TopBar(
                      live: live,
                      onBack: widget.onBack,
                      title: channel?.name.replaceAll(RegExp(r'\s*\|\s*[A-Z]{2}$'), '') ?? '',
                      subtitle: channel?.group ?? '',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _Fade(
                    visible: _visible,
                    child: _BottomBar(
                      engine: engine,
                      state: widget.state,
                      live: live,
                      onMute: _toggleMute,
                      onSkip: _skip,
                      onVolume: (v) {
                        engine.setVolume(v);
                        _poke();
                      },
                    ),
                  ),
                ),
                Center(
                  child: AnimatedOpacity(
                    opacity: _hud == null ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: _HudPill(text: _hud ?? ''),
                  ),
                ),
                _StatusLayer(engine: engine),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Feedback de carga: spinner mientras abre o rellena el buffer, "Reconectando…"
/// durante los reintentos y, si no hay manera, el error con botón "Reintentar".
class _StatusLayer extends StatelessWidget {
  const _StatusLayer({required this.engine});
  final PlayerEngine engine;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackStatus>(
      valueListenable: engine.status,
      builder: (context, status, _) {
        return StreamBuilder<bool>(
          stream: engine.player.stream.buffering,
          initialData: engine.player.state.buffering,
          builder: (context, buffering) {
            final phase = status.phase;
            if (phase == PlaybackPhase.failed) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 36),
                      const SizedBox(height: 10),
                      Text(status.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                      if (status.detail.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Motivo técnico (sin credenciales): ayuda a distinguir VPN/bloqueo
                        // del proveedor, límite de conexiones, red caída, etc.
                        Text(status.detail,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                        onPressed: engine.retry,
                      ),
                    ],
                  ),
                ),
              );
            }
            final loading = phase == PlaybackPhase.loading ||
                phase == PlaybackPhase.retrying ||
                (phase == PlaybackPhase.playing && (buffering.data ?? false));
            if (!loading) return const SizedBox.shrink();
            return IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    ),
                    if (status.message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(status.message, style: const TextStyle(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: child,
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.live,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool live;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xCC000000), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 8, 12, 20, 28),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                tooltip: 'Volver',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
              ),
            if (live) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('EN VIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.engine,
    required this.state,
    required this.live,
    required this.onMute,
    required this.onSkip,
    required this.onVolume,
  });

  final PlayerEngine engine;
  final VideoState state;
  final bool live;
  final VoidCallback onMute;
  final ValueChanged<int> onSkip;
  final ValueChanged<double> onVolume;

  /// Por debajo de este ancho no caben slider de volumen + 7 botones (móvil vertical).
  static const _compactWidth = 540.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < _compactWidth;
      return _buildBar(context, compact);
    });
  }

  Widget _buildBar(BuildContext context, bool compact) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0xDD000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!live) _SeekBar(engine: engine),
            Row(
              children: [
                if (!live)
                  _RoundButton(
                    icon: Icons.replay_10_rounded,
                    tooltip: 'Retroceder 10 s (←)',
                    onPressed: () => onSkip(-10),
                  ),
                StreamBuilder<bool>(
                  stream: engine.player.stream.playing,
                  initialData: engine.player.state.playing,
                  builder: (context, snap) {
                    final playing = snap.data ?? false;
                    return _RoundButton(
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: playing ? 'Pausar (Espacio)' : 'Reproducir (Espacio)',
                      size: 30,
                      onPressed: engine.togglePlay,
                    );
                  },
                ),
                if (!live)
                  _RoundButton(
                    icon: Icons.forward_10_rounded,
                    tooltip: 'Avanzar 10 s (→)',
                    onPressed: () => onSkip(10),
                  ),
                const SizedBox(width: 4),
                StreamBuilder<double>(
                  stream: engine.volumeStream,
                  initialData: engine.volume,
                  builder: (context, snap) {
                    final v = (snap.data ?? 100).clamp(0, 100).toDouble();
                    return Row(
                      children: [
                        _RoundButton(
                          icon: v == 0
                              ? Icons.volume_off_rounded
                              : v < 40
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded,
                          tooltip: v == 0 ? 'Activar sonido (M)' : 'Silenciar (M)',
                          onPressed: onMute,
                        ),
                        // En pantallas estrechas solo queda el botón de silencio: el volumen
                        // se maneja con las teclas físicas del dispositivo.
                        if (!compact) ...[
                          SizedBox(
                            width: 110,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.cyan,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Semantics(
                                label: 'Volumen',
                                value: '${v.round()}%',
                                child: Slider(value: v, min: 0, max: 100, onChanged: onVolume),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 38,
                            child: Text('${v.round()}%',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const Spacer(),
                _TracksButton(engine: engine),
                PopupMenuButton<AspectMode>(
                  tooltip: 'Relación de aspecto',
                  icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
                  onSelected: engine.setAspect,
                  itemBuilder: (_) => [
                    for (final m in AspectMode.values) PopupMenuItem(value: m, child: Text(m.label)),
                  ],
                ),
                _RoundButton(
                  icon: state.isFullscreen()
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  tooltip: 'Pantalla completa (F)',
                  size: 28,
                  onPressed: state.toggleFullscreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de progreso con tiempo transcurrido / total.
class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.engine});
  final PlayerEngine engine;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag; // segundos mientras se arrastra

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    return StreamBuilder<Duration>(
      stream: e.durationStream,
      initialData: e.duration,
      builder: (context, durSnap) {
        final total = durSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: e.positionStream,
          initialData: e.position,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            final value = (_drag ?? pos.inMilliseconds.toDouble()).clamp(0, max > 0 ? max : 1).toDouble();
            return Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(_fmt(Duration(milliseconds: value.round())),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.violet,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Semantics(
                      label: 'Progreso',
                      value: _fmt(pos),
                      child: Slider(
                        value: value,
                        min: 0,
                        max: max > 0 ? max : 1,
                        onChanged: max > 0 ? (v) => setState(() => _drag = v) : null,
                        onChangeEnd: (v) async {
                          await e.seek(Duration(milliseconds: v.round()));
                          if (mounted) setState(() => _drag = null);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(_fmt(total),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Menú de pistas de audio y subtítulos.
class _TracksButton extends StatelessWidget {
  const _TracksButton({required this.engine});
  final PlayerEngine engine;

  static String _label(String id, String? title, String? language, int n) {
    if (id == 'auto') return 'Automático';
    if (id == 'no') return 'Desactivados';
    final parts = [if (title != null && title.isNotEmpty) title, if (language != null && language.isNotEmpty) language];
    return parts.isEmpty ? 'Pista $n' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: engine.tracksStream,
      initialData: engine.player.state.tracks,
      builder: (context, snap) {
        final tracks = snap.data ?? const Tracks();
        final audio = tracks.audio;
        final subs = tracks.subtitle;
        final hasChoice = audio.length > 3 || subs.length > 2;
        return PopupMenuButton<Object>(
          tooltip: 'Audio y subtítulos',
          enabled: audio.isNotEmpty || subs.isNotEmpty,
          icon: Icon(Icons.subtitles_rounded,
              color: hasChoice ? Colors.white : Colors.white70),
          onSelected: (t) {
            if (t is AudioTrack) engine.setAudioTrack(t);
            if (t is SubtitleTrack) engine.setSubtitleTrack(t);
          },
          itemBuilder: (_) => [
            const PopupMenuItem<Object>(enabled: false, child: Text('Audio')),
            for (var i = 0; i < audio.length; i++)
              PopupMenuItem<Object>(
                value: audio[i],
                child: Text(_label(audio[i].id, audio[i].title, audio[i].language, i)),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<Object>(enabled: false, child: Text('Subtítulos')),
            for (var i = 0; i < subs.length; i++)
              PopupMenuItem<Object>(
                value: subs[i],
                child: Text(_label(subs[i].id, subs[i].title, subs[i].language, i)),
              ),
          ],
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        iconSize: size,
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onPressed,
      );
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );
}
