import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/cache/disk_image_cache.dart';

/// Caché de imágenes de toda la app (logos de canales y pósteres).
final diskImageCacheProvider = Provider<DiskImageCache>((ref) {
  return DiskImageCache(
    directory: () async {
      final base = await getApplicationCacheDirectory();
      return Directory('${base.path}${Platform.pathSeparator}images');
    },
    fetcher: httpFetchImage,
  );
});

/// Imagen de red con caché en disco y un marcador mientras carga o si falla.
class CachedImage extends ConsumerStatefulWidget {
  const CachedImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;

  /// Ancho al que decodificar (px): evita decodificar 4000×6000 para un póster de 150.
  final int? cacheWidth;

  @override
  ConsumerState<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends ConsumerState<CachedImage> {
  Future<File?>? _file;

  @override
  void initState() {
    super.initState();
    _file = _resolve();
  }

  @override
  void didUpdateWidget(CachedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _file = _resolve();
  }

  Future<File?>? _resolve() =>
      widget.url.isEmpty ? null : ref.read(diskImageCacheProvider).fetch(widget.url);

  @override
  Widget build(BuildContext context) {
    final future = _file;
    if (future == null) return widget.fallback;
    return FutureBuilder<File?>(
      future: future,
      builder: (context, snap) {
        final f = snap.data;
        if (f == null) return widget.fallback;
        return Image.file(
          f,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          excludeFromSemantics: true,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => widget.fallback,
        );
      },
    );
  }
}
