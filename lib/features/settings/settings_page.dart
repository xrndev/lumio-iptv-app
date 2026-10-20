import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../design_system/widgets/glass_card.dart';
import '../player/player_providers.dart';
import '../playlists/playlist_providers.dart';
import '../playlists/presentation/add_source_dialog.dart';
import 'language_switcher.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider);
    final channels = ref.watch(playlistProvider).valueOrNull?.channels.length;
    final s = Theme.of(context).colorScheme;

    return GlassCard(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(AppLocalizations.of(context).navSettings,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).settingsSource, style: TextStyle(color: s.secondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: s.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: source == null
                ? Row(children: [
                    Icon(Icons.playlist_remove_rounded, color: s.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(AppLocalizations.of(context).noSavedSource)),
                    FilledButton(
                      onPressed: () => showAddSourceDialog(context),
                      child: Text(AppLocalizations.of(context).addSource),
                    ),
                  ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.dns_rounded, color: s.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(source.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (channels != null)
                                Text(AppLocalizations.of(context).channelsCount(channels), style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).settingsStoredNote,
                        style: TextStyle(color: s.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: Text(AppLocalizations.of(context).changeSource),
                          onPressed: () => showAddSourceDialog(context),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: s.error),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(AppLocalizations.of(context).deleteSource),
                          onPressed: () => _confirmDelete(context, ref),
                        ),
                      ]),
                    ],
                  ),
          ),
          const SizedBox(height: 28),
          Text(AppLocalizations.of(context).settingsLanguage,
              style: TextStyle(color: s.secondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 240, child: LanguageSwitcher(extended: true)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext).deleteSourceTitle),
        content: Text(AppLocalizations.of(dialogContext).deleteSourceBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppLocalizations.of(dialogContext).commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AppLocalizations.of(dialogContext).commonDelete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(playerEngineProvider).stop();
    ref.read(currentChannelProvider.notifier).state = null;
    await ref.read(playlistProvider.notifier).clear();
  }
}
