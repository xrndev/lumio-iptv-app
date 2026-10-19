/// Qué hacer cuando un stream no abre o no llega a mostrar imagen.
///
/// Los proveedores IPTV fallan a menudo por razones transitorias: con una sola
/// conexión permitida, al cambiar de canal el servidor puede seguir contando la
/// anterior unos instantes; y algunos canales abren por `.m3u8` pero no por `.ts`.
enum RecoveryAction {
  /// Esperar un momento y reabrir la misma URL.
  retrySame,

  /// Probar la URL alternativa (otro formato del mismo canal).
  tryAlternate,

  /// Rendirse y avisar al usuario.
  giveUp,
}

class PlaybackRecovery {
  PlaybackRecovery({this.hasAlternate = false});

  final bool hasAlternate;
  int _failures = 0;

  /// Espera antes de reabrir la misma URL (da tiempo a liberar la conexión previa).
  static const retryDelay = Duration(milliseconds: 1500);

  /// Sin imagen pasado este tiempo se considera un fallo.
  static const watchdog = Duration(seconds: 15);

  int get failures => _failures;

  /// Registra un fallo y devuelve la siguiente acción.
  RecoveryAction onFailure() {
    _failures++;
    if (_failures == 1) return RecoveryAction.retrySame;
    if (_failures == 2 && hasAlternate) return RecoveryAction.tryAlternate;
    return RecoveryAction.giveUp;
  }
}
