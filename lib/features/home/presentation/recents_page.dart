import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../library/library_providers.dart';
import '../../player/presentation/player_page.dart';
import '../../playlists/playlist_providers.dart';
import 'channel_tile.dart';

/// "Recientes": canales vistos hace poco, el último primero.
class RecentsPage extends ConsumerWidget {
  const RecentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(currentLibraryProvider);
    final channels = ref.watch(channelsByUidProvider);
    final items = [
      for (final uid in lib.recentUids())
        if (channels[uid] != null) channels[uid]!,
    ];
    final s = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(children: [
              Text(AppLocalizations.of(context).navRecents,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => ref.read(libraryProvider.notifier).clearRecents(),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(AppLocalizations.of(context).recentsClear),
                ),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context).recentsEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: s.onSurfaceVariant, height: 1.5)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    itemCount: items.length,
                    itemExtent: channelTileExtent,
                    itemBuilder: (context, i) => ChannelTile(
                      channel: items[i],
                      onTap: () => openPlayer(context, ref, items[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
