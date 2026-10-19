import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../design_system/theme/app_theme.dart';
import '../data/player_engine.dart';
import '../player_providers.dart';

/// Controles superpuestos: play/pausa, volumen (slider, mute, rueda, ↑/↓),
/// relación de aspecto y pantalla completa. Se ocultan solos tras 3 s.
class PlayerOverlay extends ConsumerStatefulWidget {
  const PlayerOverlay({super.key, required this.state});

  final VideoState state;

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

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      _changeVolume(5);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _changeVolume(-5);
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

    return Focus(
      focusNode: _focus,
      autofocus: false,
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
                // Barra superior
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _Fade(
                    visible: _visible,
                    child: _TopBar(
                      title: channel?.name.replaceAll(RegExp(r'\s*\|\s*[A-Z]{2}$'), '') ?? '',
                      subtitle: channel?.group ?? '',
                    ),
                  ),
                ),
                // Barra inferior
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _Fade(
                    visible: _visible,
                    child: _BottomBar(
                      engine: engine,
                      state: widget.state,
                      onMute: _toggleMute,
                      onVolume: (v) {
                        engine.setVolume(v);
                        _poke();
                      },
                    ),
                  ),
                ),
                // HUD de volumen
                Center(
                  child: AnimatedOpacity(
                    opacity: _hud == null ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: _HudPill(text: _hud ?? ''),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  const _TopBar({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.live,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('EN VIVO',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            ),
            const SizedBox(width: 12),
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
    required this.onMute,
    required this.onVolume,
  });

  final PlayerEngine engine;
  final VideoState state;
  final VoidCallback onMute;
  final ValueChanged<double> onVolume;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Color(0xDD000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 32, 12, 10),
        child: Row(
          children: [
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
                    SizedBox(
                      width: 120,
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
                );
              },
            ),
            const Spacer(),
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
      ),
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
