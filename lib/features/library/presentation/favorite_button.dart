import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/library/library_data.dart';
import '../library_providers.dart';

const _gold = Color(0xFFFFC857);

/// Estrella para marcar/desmarcar un canal, película o serie como favorito.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.kind,
    required this.uid,
    this.size = 24,
    this.inactiveColor,
    this.notify = true,
    this.overlay = false,
  });

  final LibraryKind kind;
  final String uid;
  final double size;
  final Color? inactiveColor;

  /// Muestra un aviso breve ("Añadido a favoritos") con la opción de deshacer.
  final bool notify;

  /// Variante compacta con fondo oscuro, para ponerla encima de pósteres.
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(isFavoriteProvider((kind: kind, uid: uid)));
    final off = inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      toggled: fav,
      label: fav ? AppLocalizations.of(context).favRemove : AppLocalizations.of(context).favAdd,
      excludeSemantics: true,
      child: IconButton(
        tooltip: fav ? AppLocalizations.of(context).favRemove : AppLocalizations.of(context).favAdd,
        constraints: overlay
            ? const BoxConstraints(minWidth: 36, minHeight: 36)
            : const BoxConstraints(minWidth: 48, minHeight: 48),
        style: overlay
            ? IconButton.styleFrom(backgroundColor: Colors.black54, padding: EdgeInsets.zero)
            : null,
        iconSize: size,
        color: fav ? _gold : off,
        icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded),
        onPressed: () => _toggle(context, ref, fav),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool wasFavorite) async {
    final notifier = ref.read(libraryProvider.notifier);
    await notifier.toggleFavorite(kind, uid);
    if (!notify || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        content: Text(wasFavorite ? AppLocalizations.of(context).favRemoved : AppLocalizations.of(context).favAdded),
        action: SnackBarAction(label: AppLocalizations.of(context).undo, onPressed: () => notifier.toggleFavorite(kind, uid)),
      ));
  }
}
