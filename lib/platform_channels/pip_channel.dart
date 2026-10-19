import 'dart:io';

import 'package:flutter/services.dart';

/// Picture-in-Picture / ventana flotante.
///
/// Android: `enterPictureInPictureMode` en MainActivity (lado nativo pendiente).
/// iOS: AVPictureInPictureController (pendiente).
/// Desktop: se resolverá con `window_manager` (always-on-top + tamaño mini),
/// sin canal nativo propio.
class PipChannel {
  const PipChannel._();

  static const _channel = MethodChannel('lumio/pip');

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Devuelve `false` si la plataforma no lo soporta o el lado nativo falla.
  static Future<bool> enter({int numerator = 16, int denominator = 9}) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('enter', {
            'numerator': numerator,
            'denominator': denominator,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Android TV / leanback (para activar `ScreenType` + foco TV).
  static Future<bool> isTelevision() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isTelevision') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
