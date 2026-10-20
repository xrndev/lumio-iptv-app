import 'dart:async';

import 'package:cast/cast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/channel.dart';
import 'cast_message.dart';

/// Receptor multimedia por defecto de Google (reproduce URL de vídeo sin app propia).
const _defaultMediaReceiver = 'CC1AD845';

class CastState {
  const CastState({this.device, this.connecting = false, this.error});
  final CastDevice? device;
  final bool connecting;
  final String? error;
  bool get casting => device != null && !connecting;
}

/// Emite el contenido actual a un Chromecast de la red local.
class CastController extends Notifier<CastState> {
  CastSession? _session;
  int _requestId = 0;
  StreamSubscription<CastSessionState>? _sub;

  @override
  CastState build() {
    ref.onDispose(stop);
    return const CastState();
  }

  Future<List<CastDevice>> discover() => CastDiscoveryService().search(timeout: const Duration(seconds: 5));

  /// Conecta con [device] y le manda [channel] (en [startAt] si es una película).
  Future<void> start(CastDevice device, Channel channel, {Duration? startAt}) async {
    await stop();
    state = CastState(device: device, connecting: true);
    try {
      final session = await CastSessionManager().startSession(device, const Duration(seconds: 8));
      _session = session;
      final loaded = Completer<void>();
      _sub = session.stateStream.listen((s) {
        if (s == CastSessionState.connected && !loaded.isCompleted) {
          session.sendMessage(CastSession.kNamespaceMedia,
              buildLoadMessage(channel, requestId: ++_requestId, startAt: startAt));
          loaded.complete();
          state = CastState(device: device);
        } else if (s == CastSessionState.closed) {
          _cleanup();
        }
      });
      session.sendMessage(CastSession.kNamespaceReceiver, {
        'type': 'LAUNCH',
        'appId': _defaultMediaReceiver,
        'requestId': ++_requestId,
      });
      await loaded.future.timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Chromecast: $e');
      await stop();
      state = const CastState(error: 'connect_failed'); // sin texto: la UI no lo muestra
    }
  }

  Future<void> stop() async {
    final session = _session;
    _cleanup();
    if (session != null) {
      try {
        session.sendMessage(CastSession.kNamespaceReceiver, {'type': 'STOP', 'requestId': ++_requestId});
        await session.close();
      } catch (_) {}
    }
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _session = null;
    if (state.device != null || state.connecting) state = const CastState();
  }
}

final castControllerProvider = NotifierProvider<CastController, CastState>(CastController.new);
