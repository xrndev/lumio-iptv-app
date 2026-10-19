import 'package:flutter/services.dart';

/// Acciones de las teclas multimedia de un mando de TV (Fire TV, Android TV, teclados
/// multimedia). En el mando de Amazon: ⏪ rebobinar, ⏯ play/pausa y ⏩ avance rápido.
enum RemoteAction { playPause, play, pause, seekBack, seekForward, none }

/// Traduce una tecla multimedia en una acción; `none` si no es una tecla multimedia.
RemoteAction mapMediaKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.mediaPlayPause) return RemoteAction.playPause;
  if (key == LogicalKeyboardKey.mediaPlay) return RemoteAction.play;
  if (key == LogicalKeyboardKey.mediaPause) return RemoteAction.pause;
  if (key == LogicalKeyboardKey.mediaRewind || key == LogicalKeyboardKey.mediaTrackPrevious) {
    return RemoteAction.seekBack;
  }
  if (key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaTrackNext) {
    return RemoteAction.seekForward;
  }
  return RemoteAction.none;
}

/// Segundos que salta cada pulsación de rebobinar/avanzar (solo películas y series).
const remoteSeekSeconds = 10;
