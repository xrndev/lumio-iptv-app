import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_system/theme/app_theme.dart';
import 'design_system/widgets/glass_card.dart';
import 'features/home/presentation/home_page.dart';
import 'features/settings/locale_providers.dart';
import 'l10n/app_localizations.dart';
import 'platform_channels/tv_provider.dart';

/// Factor mínimo de texto en TV: se lee desde ~3 m, y Android TV / Fire TV usan una
/// densidad que deja el texto de móvil pequeño.
const tvTextScale = 1.15;

/// En TV sube el texto al mínimo [tvTextScale]; respeta una escala del sistema que ya sea mayor.
/// Fuera de TV no cambia nada.
TextScaler tvAwareTextScaler(TextScaler current, {required bool tv}) {
  if (!tv) return current;
  return current.scale(1) < tvTextScale ? const TextScaler.linear(tvTextScale) : current;
}

class IptvApp extends ConsumerWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tv = ref.watch(isTelevisionProvider).valueOrNull ?? false;
    final locale = ref.watch(localeProvider).valueOrNull ?? systemLocale();
    return MaterialApp(
      title: 'Lumio',
      debugShowCheckedModeBanner: false,
      // Siempre tema oscuro (identidad de la marca), sea cual sea el modo del sistema.
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (!tv || child == null) return child ?? const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        return GlassBlur(
          enabled: false,
          child: MediaQuery(
            data: mq.copyWith(textScaler: tvAwareTextScaler(mq.textScaler, tv: tv)),
            child: child,
          ),
        );
      },
      home: const HomePage(),
    );
  }
}
