import '../../core/library/library_data.dart';
import '../../core/models/channel.dart';

/// Decide cuándo guardar el progreso de una película o episodio mientras se reproduce.
///
/// Lógica pura (sin Flutter ni reloj propio) para poder testearla:
/// - guarda como mucho una vez cada [interval] y solo si la posición ha avanzado;
/// - ignora lecturas inválidas (posición 0 o duración desconocida), como las que salen
///   cuando se detiene el reproductor: así nunca se pisa el progreso real con un 0;
/// - al terminar ([finish]) guarda la última posición buena conocida.
class ProgressTracker {
  ProgressTracker({this.interval = const Duration(seconds: 5)});

  final Duration interval;

  Channel? _channel;
  int _pos = 0;
  int _dur = 0;
  int _lastSavedPos = -1;
  int _lastSavedAt = 0;
  bool _dirty = false;

  bool get isTracking => _channel != null;

  /// Empieza a seguir [channel]; solo vale para películas y episodios.
  void start(Channel channel) {
    _channel = channel.media == null ? null : channel;
    _pos = 0;
    _dur = 0;
    _lastSavedPos = -1;
    _lastSavedAt = 0;
    _dirty = false;
  }

  /// Llamar con cada actualización de posición. Devuelve lo que hay que guardar, o `null`.
  ProgressEntry? onTick(int posMs, int durMs, int nowMs) {
    if (_channel == null || posMs <= 0 || durMs <= 0) return null;
    _pos = posMs;
    _dur = durMs;
    _dirty = posMs != _lastSavedPos;
    final due = nowMs - _lastSavedAt >= interval.inMilliseconds;
    if (!due || !_dirty || (_lastSavedPos >= 0 && (posMs - _lastSavedPos).abs() < 1000)) {
      return null;
    }
    return _save(nowMs);
  }

  /// Al parar o cambiar de contenido: guarda la última posición buena si no estaba guardada.
  ProgressEntry? finish(int nowMs) {
    if (_channel == null || !_dirty || _pos <= 0 || _dur <= 0) {
      _channel = null;
      return null;
    }
    final e = _save(nowMs);
    _channel = null;
    return e;
  }

  ProgressEntry _save(int nowMs) {
    _lastSavedPos = _pos;
    _lastSavedAt = nowMs;
    _dirty = false;
    final c = _channel!;
    final m = c.media!;
    return ProgressEntry(
      key: c.uid,
      isEpisode: m.isEpisode,
      id: m.id,
      ext: m.ext,
      title: m.title,
      poster: m.poster,
      subtitle: m.subtitle,
      posMs: _pos,
      durMs: _dur,
      t: nowMs,
    );
  }
}
