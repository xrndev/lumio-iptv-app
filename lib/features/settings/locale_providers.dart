import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/locale_store.dart';

/// Idiomas disponibles, en el orden en que se muestran.
const supportedLanguageCodes = ['es', 'en'];

final localeStoreProvider = Provider<LocaleStore>((ref) => FileLocaleStore());

/// Idioma de la app: el guardado por el usuario o, si no hay, el del sistema
/// (español si lo es; cualquier otro → inglés).
class LocaleController extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final saved = await ref.read(localeStoreProvider).read();
    if (saved != null && supportedLanguageCodes.contains(saved)) return Locale(saved);
    return systemLocale();
  }

  Future<void> set(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    state = AsyncData(Locale(code));
    await ref.read(localeStoreProvider).write(code);
  }
}

Locale systemLocale() =>
    PlatformDispatcher.instance.locale.languageCode == 'es' ? const Locale('es') : const Locale('en');

final localeProvider = AsyncNotifierProvider<LocaleController, Locale>(LocaleController.new);
