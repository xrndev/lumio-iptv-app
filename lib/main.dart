import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/storage/legacy_migration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Antes de que nada lea el almacén: conserva la fuente guardada de "IPTV Launcher".
  if (Platform.isWindows) await migrateLegacyWindowsData();
  runApp(const ProviderScope(child: IptvApp()));
}
