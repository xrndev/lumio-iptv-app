import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/models/channel.dart';
import 'data/player_engine.dart';

/// Un único motor para toda la app: el stream sobrevive a cambios de layout.
final playerEngineProvider = Provider<PlayerEngine>((ref) {
  final engine = PlayerEngine();
  ref.onDispose(engine.dispose);
  // Solo debug: reproduce una URL al arrancar para diagnosticar sin UI.
  final autoplay = kDebugMode ? Platform.environment['IPTV_AUTOPLAY'] : null;
  if (autoplay != null) engine.player.open(Media(autoplay));
  // Solo debug: IPTV_AUTOPLAY_SEQ="url|url|url" cambia de canal cada 12 s (prueba de zapping).
  final seq = kDebugMode ? Platform.environment['IPTV_AUTOPLAY_SEQ']?.split('|') : null;
  if (seq != null) {
    var i = 0;
    final every = int.tryParse(Platform.environment['IPTV_SEQ_SECS'] ?? '') ?? 12;
    final t = Timer.periodic(Duration(seconds: every), (t) {
      if (i >= seq.length) return t.cancel();
      File('${Directory.systemTemp.path}/iptv_player.log').writeAsStringSync(
          '${DateTime.now().toIso8601String().substring(11, 23)} [seq] abrir #${i + 1}\n',
          mode: FileMode.append);
      engine.player.open(Media(seq[i++]));
    });
    ref.onDispose(t.cancel);
    File('${Directory.systemTemp.path}/iptv_player.log').writeAsStringSync(
        '${DateTime.now().toIso8601String().substring(11, 23)} [seq] abrir #1\n',
        mode: FileMode.append);
    engine.player.open(Media(seq[i++]));
  }
  return engine;
});

final currentChannelProvider = StateProvider<Channel?>((ref) => null);

/// Abre un canal o contenido; con [startAt] empieza en ese punto (reanudar).
typedef PlayChannel = Future<void> Function(Channel channel, {Duration? startAt});

/// Cambia de canal: actualiza el estado y abre el stream.
final playChannelProvider = Provider<PlayChannel>((ref) {
  return (channel, {startAt}) async {
    ref.read(currentChannelProvider.notifier).state = channel;
    await ref.read(playerEngineProvider).play(channel, startAt: startAt);
  };
});
