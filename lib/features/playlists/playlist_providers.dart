import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/channel.dart';
import '../../core/network/playlist_downloader.dart';
import '../../core/network/xtream_client.dart';
import '../../core/parsing/m3u_parser.dart';

final playlistDownloaderProvider = Provider((ref) => PlaylistDownloader());
final xtreamClientProvider = Provider((ref) => XtreamClient());

/// Datos de la cuenta Xtream activa (estado y caducidad), si la fuente es Xtream.
final xtreamAccountProvider = StateProvider<XtreamAccount?>((ref) => null);

/// Playlist activa. `null` = aún no se ha cargado ninguna fuente.
class PlaylistController extends AsyncNotifier<M3uPlaylist?> {
  @override
  Future<M3uPlaylist?> build() async => null;

  Future<void> loadUrl(String url) async {
    ref.read(xtreamAccountProvider.notifier).state = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final file = await ref.read(playlistDownloaderProvider).download(url);
      return M3uParser.parseFile(file.path);
    });
  }

  Future<void> loadXtream(XtreamCredentials creds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final r = await ref.read(xtreamClientProvider).loadLive(creds);
      ref.read(xtreamAccountProvider.notifier).state = r.account;
      return r.playlist;
    });
  }

  Future<void> loadFile(String path) async {
    ref.read(xtreamAccountProvider.notifier).state = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!await File(path).exists()) throw FileSystemException('No existe', path);
      return M3uParser.parseFile(path);
    });
  }
}

final playlistProvider =
    AsyncNotifierProvider<PlaylistController, M3uPlaylist?>(PlaylistController.new);

/// Filtro de búsqueda en memoria. TODO: sustituir por FTS5 (drift) para 50k+.
final channelSearchProvider = StateProvider<String>((ref) => '');

final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final all = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  final q = ref.watch(channelSearchProvider).trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((c) => c.name.toLowerCase().contains(q)).toList(growable: false);
});
