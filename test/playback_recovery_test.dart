import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_launcher/features/player/data/playback_recovery.dart';

void main() {
  test('con URL alternativa: reintenta, prueba el otro formato y se rinde', () {
    final r = PlaybackRecovery(hasAlternate: true);
    expect(r.onFailure(), RecoveryAction.retrySame);
    expect(r.onFailure(), RecoveryAction.tryAlternate);
    expect(r.onFailure(), RecoveryAction.giveUp);
    expect(r.onFailure(), RecoveryAction.giveUp); // y sigue rindiéndose
  });

  test('sin URL alternativa: reintenta una vez y se rinde', () {
    final r = PlaybackRecovery();
    expect(r.onFailure(), RecoveryAction.retrySame);
    expect(r.onFailure(), RecoveryAction.giveUp);
    expect(r.failures, 2);
  });

  test('el margen de espera es razonable', () {
    expect(PlaybackRecovery.retryDelay, greaterThanOrEqualTo(const Duration(seconds: 1)));
    expect(PlaybackRecovery.watchdog, greaterThan(PlaybackRecovery.retryDelay));
  });
}
