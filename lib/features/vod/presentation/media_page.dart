import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/library/library_data.dart';
import '../../../core/models/media.dart';
import '../../../l10n/error_text.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/widgets/cached_logo.dart';
import '../../../design_system/widgets/focus_ring.dart';
import '../../../design_system/widgets/glass_card.dart';
import '../../../design_system/widgets/wheel_scroll_row.dart';
import '../../library/presentation/favorite_button.dart';
import '../../playlists/playlist_providers.dart';
import '../../playlists/presentation/add_source_dialog.dart';
import '../vod_providers.dart';
import 'detail_pages.dart';

/// Rejilla de películas o series con búsqueda y filtro por categoría.
class MediaPage extends ConsumerWidget {
  const MediaPage({super.key, required this.kind});

  final MediaKind kind;

  String _title(AppLocalizations l) => kind == MediaKind.movies ? l.navMovies : l.navSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final title = _title(l);
    final creds = ref.watch(xtreamCredentialsProvider);

    return GlassCard(
      child: creds == null
          ? _Info(
              icon: Icons.movie_filter_rounded,
              text: l.mediaRequiresXtream(title),
              action: l.addXtreamAccount,
              onAction: () => showAddSourceDialog(context),
            )
          : ref.watch(mediaCatalogProvider(kind)).when(
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l.mediaLoading(title.toLowerCase())),
                    ],
                  ),
                ),
                error: (e, _) => _Info(
                  icon: Icons.error_outline_rounded,
                  text: l.catalogLoadError(localizedError(l, e)),
                  action: l.commonRetry,
                  onAction: () => ref.invalidate(mediaCatalogProvider(kind)),
                ),
                data: (catalog) => catalog == null
                    ? const SizedBox.shrink()
                    : _Browser(kind: kind, title: title, catalog: catalog),
              ),
    );
  }
}

class _Browser extends ConsumerWidget {
  const _Browser({required this.kind, required this.title, required this.catalog});

  final MediaKind kind;
  final String title;
  final MediaCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(visibleMediaProvider(kind));
    final selected = ref.watch(mediaGroupProvider(kind));
    final s = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: s.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  items.length == catalog.items.length
                      ? '${catalog.items.length}'
                      : '${items.length} / ${catalog.items.length}',
                  style: TextStyle(color: s.primary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  onChanged: (v) => ref.read(mediaSearchProvider(kind).notifier).state = v,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).mediaSearchHint(title.toLowerCase()),
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (catalog.groups.length > 1)
          WheelScrollRow(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              CategoryChip(
                  label: AppLocalizations.of(context).chipAllCategories,
                  selected: selected == null,
                  onTap: () => ref.read(mediaGroupProvider(kind).notifier).state = null),
              for (final g in catalog.groups)
                CategoryChip(
                    label: g,
                    selected: selected == g,
                    onTap: () => ref.read(mediaGroupProvider(kind).notifier).state = g),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(AppLocalizations.of(context).noResults, style: TextStyle(color: s.onSurfaceVariant)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => PosterCard(
                    entry: items[i],
                    onTap: () => openMediaDetail(context, items[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Póster con título, año y valoración.
class PosterCard extends StatelessWidget {
  const PosterCard({super.key, required this.entry, required this.onTap});

  final MediaEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final subtitle = [if (entry.year.isNotEmpty) entry.year].join(' · ');

    return Semantics(
      button: true,
      label: entry.title,
      child: FocusRing(
        radius: 16,
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: s.surfaceContainerHigh,
                      child: entry.poster.isEmpty
                          ? Icon(Icons.movie_rounded, size: 40, color: s.onSurfaceVariant)
                          : CachedImage(
                              url: entry.poster,
                              fit: BoxFit.cover,
                              cacheWidth: 340,
                              fallback:
                                  Icon(Icons.movie_rounded, size: 40, color: s.onSurfaceVariant),
                            ),
                    ),
                  ),
                  if (entry.rating != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Sin estrella: la estrella es de favoritos.
                        child: Text(entry.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: FavoriteButton(
                      kind: entry is VodItem ? LibraryKind.movie : LibraryKind.series,
                      uid: entry.uid,
                      size: 20,
                      overlay: true,
                      inactiveColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(cleanTitle(entry.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: s.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text, required this.action, required this.onAction});
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (r) => AppColors.accentGradient.createShader(r),
              child: Icon(icon, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
