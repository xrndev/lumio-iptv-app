import '../../core/models/channel.dart';

/// Mensaje LOAD del receptor multimedia por defecto de Chromecast.
///
/// Lógica pura para testearla. El Chromecast no entiende MPEG-TS en bruto: para directo
/// se usa la variante HLS (`altUrl`) cuando existe.
Map<String, dynamic> buildLoadMessage(Channel channel, {required int requestId, Duration? startAt}) {
  final live = channel.isLive;
  final url = live ? (channel.altUrl ?? channel.url) : channel.url;
  return {
    'type': 'LOAD',
    'requestId': requestId,
    'autoplay': true,
    if (startAt != null && !live) 'currentTime': startAt.inSeconds,
    'media': {
      'contentId': url,
      'streamType': live ? 'LIVE' : 'BUFFERED',
      'contentType': castContentType(url),
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': channel.media?.title ?? channel.name,
      },
    },
  };
}

String castContentType(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  if (path.endsWith('.m3u8')) return 'application/x-mpegURL';
  if (path.endsWith('.mkv')) return 'video/x-matroska';
  if (path.endsWith('.ts')) return 'video/mp2t';
  return 'video/mp4';
}
