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

  void _beginLoad({bool keepAccount = false}) {
    if (!keepAccount) ref.read(xtreamAccountProvider.notifier).state = null;
    ref.read(selectedGroupProvider.notifier).state = null;
    ref.read(channelSearchProvider.notifier).state = '';
    state = const AsyncLoading();
  }

  Future<void> loadUrl(String url) async {
    _beginLoad();
    state = await AsyncValue.guard(() async {
      final file = await ref.read(playlistDownloaderProvider).download(url);
      return M3uParser.parseFile(file.path);
    });
  }

  Future<void> loadXtream(XtreamCredentials creds) async {
    _beginLoad(keepAccount: true);
    state = await AsyncValue.guard(() async {
      final r = await ref.read(xtreamClientProvider).loadLive(creds);
      ref.read(xtreamAccountProvider.notifier).state = r.account;
      return r.playlist;
    });
  }

  Future<void> loadFile(String path) async {
    _beginLoad();
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

/// Categoría seleccionada (`null` = todas).
final selectedGroupProvider = StateProvider<String?>((ref) => null);

/// Grupos de la lista activa, en orden de aparición.
final groupsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  return {for (final c in all) if (c.group.isNotEmpty) c.group}.toList(growable: false);
});

final visibleChannelsProvider = Provider<List<Channel>>((ref) {
  final all = ref.watch(playlistProvider).valueOrNull?.channels ?? const <Channel>[];
  final q = ref.watch(channelSearchProvider).trim().toLowerCase();
  final group = ref.watch(selectedGroupProvider);
  if (q.isEmpty && group == null) return all;
  return all
      .where((c) => (group == null || c.group == group) && (q.isEmpty || c.name.toLowerCase().contains(q)))
      .toList(growable: false);
});
