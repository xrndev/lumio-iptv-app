import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/widgets/glass_card.dart';
import '../player/player_providers.dart';
import '../playlists/playlist_providers.dart';
import '../playlists/presentation/add_source_dialog.dart';

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
          Text('Ajustes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Text('FUENTE', style: TextStyle(color: s.secondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
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
                    const Expanded(child: Text('No hay ninguna fuente guardada.')),
                    FilledButton(
                      onPressed: () => showAddSourceDialog(context),
                      child: const Text('Añadir fuente'),
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
                                Text('$channels canales', style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Se guarda en este equipo y se carga sola al abrir la app. '
                        'Las credenciales se almacenan cifradas por el sistema.',
                        style: TextStyle(color: s.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Cambiar fuente'),
                          onPressed: () => showAddSourceDialog(context),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: s.error),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Eliminar fuente'),
                          onPressed: () => _confirmDelete(context, ref),
                        ),
                      ]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar la fuente?'),
        content: const Text(
          'Se borrarán de este equipo la lista guardada y, si la hay, la cuenta Xtream. '
          'Tendrás que volver a añadirla para ver canales, películas y series.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(playerEngineProvider).stop();
    ref.read(currentChannelProvider.notifier).state = null;
    await ref.read(playlistProvider.notifier).clear();
  }
}
