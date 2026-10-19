import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pip_channel.dart';

/// `true` en Android TV (mando / D-Pad, sin puntero). Se resuelve una sola vez.
final isTelevisionProvider = FutureProvider<bool>((ref) => PipChannel.isTelevision());
