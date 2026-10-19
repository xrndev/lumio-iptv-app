import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/models/channel.dart';
import 'package:lumio/core/models/media.dart';
import 'package:lumio/features/cast/cast_message.dart';

void main() {
  test('directo: usa la variante HLS y streamType LIVE', () {
    final m = buildLoadMessage(
      const Channel(index: 0, name: 'La 1', url: 'http://s/live/u/p/1.ts', altUrl: 'http://s/live/u/p/1.m3u8'),
      requestId: 3,
    );
    final media = m['media'] as Map;
    expect(media['contentId'], 'http://s/live/u/p/1.m3u8');
    expect(media['contentType'], 'application/x-mpegURL');
    expect(media['streamType'], 'LIVE');
    expect(m.containsKey('currentTime'), isFalse);
    expect(m['requestId'], 3);
  });

  test('película: reanuda en el punto guardado', () {
    final m = buildLoadMessage(
      const Channel(
        index: -1,
        name: 'x',
        url: 'http://s/movie/u/p/9.mkv',
        isLive: false,
        media: MediaMeta(id: 9, isEpisode: false, ext: 'mkv', title: 'Mi peli'),
      ),
      requestId: 1,
      startAt: const Duration(minutes: 5),
    );
    expect(m['currentTime'], 300);
    final media = m['media'] as Map;
    expect(media['streamType'], 'BUFFERED');
    expect(media['contentType'], 'video/x-matroska');
    expect((media['metadata'] as Map)['title'], 'Mi peli');
  });

  test('tipo por extensión, ignorando query', () {
    expect(castContentType('http://s/a.mp4?x=1'), 'video/mp4');
    expect(castContentType('http://s/a.m3u8?token=2'), 'application/x-mpegURL');
  });
}
