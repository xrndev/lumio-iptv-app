/// Canal de una lista. Inmutable y sin closures: viaja entre Isolates sin coste.
class Channel {
  const Channel({
    required this.index,
    required this.name,
    required this.url,
    this.tvgId = '',
    this.tvgName = '',
    this.logo = '',
    this.group = '',
    this.number,
    this.catchup = '',
    this.catchupDays,
    this.catchupSource = '',
    this.userAgent,
    this.referrer,
    this.isLive = true,
    this.altUrl,
  });

  /// URL alternativa del mismo canal (p. ej. `.m3u8` si la principal es `.ts`),
  /// usada como respaldo si la principal no abre.
  final String? altUrl;

  /// `false` para películas y episodios: el reproductor muestra barra de progreso.
  final bool isLive;

  /// Posición en la lista original (orden estable, usado como clave).
  final int index;
  final String name;
  final String url;
  final String tvgId;
  final String tvgName;
  final String logo;
  final String group;

  /// `tvg-chno`: número de dial si el proveedor lo indica.
  final int? number;

  /// `catchup` (default, append, shift, flussonic, xc) y ventana en días.
  final String catchup;
  final int? catchupDays;
  final String catchupSource;

  final String? userAgent;
  final String? referrer;

  bool get supportsCatchup => catchup.isNotEmpty || catchupSource.isNotEmpty;

  /// Cabeceras HTTP a enviar al reproductor.
  Map<String, String> get httpHeaders => {
        if (userAgent != null) 'User-Agent': userAgent!,
        if (referrer != null) 'Referer': referrer!,
      };

  @override
  String toString() => 'Channel($index, $name)';
}

class M3uPlaylist {
  const M3uPlaylist({required this.channels, this.epgUrls = const [], this.skippedLines = 0});

  final List<Channel> channels;

  /// URLs XMLTV declaradas en `#EXTM3U url-tvg="a,b"` / `x-tvg-url`.
  final List<String> epgUrls;

  /// Entradas descartadas por estar malformadas (EXTINF sin URL, etc.).
  final int skippedLines;

  Set<String> get groups => {for (final c in channels) c.group};
}
