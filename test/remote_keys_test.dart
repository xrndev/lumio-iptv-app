import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/features/player/presentation/remote_keys.dart';

void main() {
  test('las teclas del mando de Fire TV se traducen a acciones del reproductor', () {
    expect(mapMediaKey(LogicalKeyboardKey.mediaPlayPause), RemoteAction.playPause);
    expect(mapMediaKey(LogicalKeyboardKey.mediaPlay), RemoteAction.play);
    expect(mapMediaKey(LogicalKeyboardKey.mediaPause), RemoteAction.pause);
    expect(mapMediaKey(LogicalKeyboardKey.mediaRewind), RemoteAction.seekBack);
    expect(mapMediaKey(LogicalKeyboardKey.mediaFastForward), RemoteAction.seekForward);
  });

  test('las teclas anterior/siguiente también rebobinan y avanzan', () {
    expect(mapMediaKey(LogicalKeyboardKey.mediaTrackPrevious), RemoteAction.seekBack);
    expect(mapMediaKey(LogicalKeyboardKey.mediaTrackNext), RemoteAction.seekForward);
  });

  test('las teclas que no son multimedia no hacen nada', () {
    for (final k in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.goBack,
      LogicalKeyboardKey.keyM,
    ]) {
      expect(mapMediaKey(k), RemoteAction.none, reason: '$k');
    }
  });
}
