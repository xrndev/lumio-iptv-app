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
  return engine;
});

final currentChannelProvider = StateProvider<Channel?>((ref) => null);

/// Cambia de canal: actualiza el estado y abre el stream.
final playChannelProvider = Provider<Future<void> Function(Channel)>((ref) {
  return (channel) async {
    ref.read(currentChannelProvider.notifier).state = channel;
    await ref.read(playerEngineProvider).play(channel);
  };
});
