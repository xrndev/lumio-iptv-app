import 'package:flutter/material.dart';

import '../../../core/library/library_data.dart';
import '../../../core/models/channel.dart';
import '../../../core/util/channel_names.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/widgets/cached_logo.dart';
import '../../../design_system/widgets/focus_ring.dart';
import '../../library/presentation/favorite_button.dart';

/// Altura fija de la fila (permite `itemExtent` y layout O(1) con 50 000 canales).
const channelTileExtent = 72.0;

/// Fila de un canal: logo, nombre limpio, calidad, favorito y, si la hay, la línea de guía.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.playing = false,
    this.subtitle,
  });

  final Channel channel;
  final VoidCallback onTap;
  final bool playing;

  /// Línea inferior (p. ej. el programa que están dando). Por defecto, la categoría.
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final name = parseChannelName(channel.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Material(
        color: playing ? s.primary.withValues(alpha: 0.14) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: playing ? s.primary.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: FocusRing(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            hoverColor: s.onSurface.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  _Logo(url: channel.logo),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: playing ? FontWeight.w700 : FontWeight.w600)),
                        subtitle ??
                            (channel.group.isEmpty
                                ? const SizedBox.shrink()
                                : Text(prettyGroupName(channel.group),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: s.onSurfaceVariant, fontSize: 12))),
                      ],
                    ),
                  ),
                  if (name.quality != null || name.hevc) _QualityBadge(name: name),
                  if (playing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.graphic_eq_rounded, color: AppColors.cyan),
                    )
                  else if (channel.supportsCatchup)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.history_rounded, size: 18, color: s.onSurfaceVariant),
                    ),
                  FavoriteButton(kind: LibraryKind.channel, uid: channel.uid, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final icon = Icon(Icons.tv_rounded, color: s.onSurfaceVariant);
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: CachedImage(url: url, fit: BoxFit.contain, cacheWidth: 96, fallback: icon),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.name});
  final ChannelName name;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final label = [if (name.quality != null) name.quality!, if (name.hevc) 'HEVC'].join(' · ');
    final is4k = name.quality == '4K';
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: (is4k ? AppColors.violet : s.onSurfaceVariant).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: is4k ? AppColors.violet : s.onSurfaceVariant)),
    );
  }
}
