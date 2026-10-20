// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navLive => 'En vivo';

  @override
  String get navMovies => 'Películas';

  @override
  String get navSeries => 'Series';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navRecents => 'Recientes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get menuCollapse => 'Contraer menú';

  @override
  String get menuExpand => 'Expandir menú';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonProgress => 'Progreso';

  @override
  String get commonWatched => 'Visto';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get chipAllChannels => 'Todos';

  @override
  String get chipAllCategories => 'Todas';

  @override
  String sourceLoadError(String error) {
    return 'No se pudo cargar la fuente:\n$error';
  }

  @override
  String get tryAnotherSource => 'Probar otra fuente';

  @override
  String get addSourceHint =>
      'Añade una lista M3U, un archivo o una cuenta Xtream Codes.';

  @override
  String get addSource => 'Añadir fuente';

  @override
  String get searchChannelHint => 'Buscar canal';

  @override
  String noticeInactive(String status) {
    return 'Tu cuenta no está activa ($status). Contacta con tu proveedor.';
  }

  @override
  String get noticeExpired =>
      'Tu suscripción ha caducado. Renueva con tu proveedor.';

  @override
  String get noticeExpiresToday => 'Tu suscripción caduca hoy.';

  @override
  String noticeExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tu suscripción caduca en $days días.',
      one: 'Tu suscripción caduca en 1 día.',
    );
    return '$_temp0';
  }

  @override
  String get singleConnectionHint =>
      'Tu cuenta permite 1 sola conexión: si la usas en otro dispositivo, este canal puede no abrirse.';

  @override
  String get continueWatching => 'Continuar viendo';

  @override
  String get myFavorites => 'Mis favoritos';

  @override
  String get kindChannels => 'Canales';

  @override
  String get favoritesNotInList => 'Tus favoritos no están en la lista actual.';

  @override
  String get favoritesNotInCatalog =>
      'Tus favoritos no están en el catálogo actual.';

  @override
  String get emptyFavoritesChannels =>
      'Aún no tienes canales favoritos.\nPulsa la ☆ de cualquier canal para guardarlo aquí.';

  @override
  String get emptyFavoritesMovies =>
      'Aún no tienes películas favoritas.\nPulsa la ☆ de un póster para guardarla aquí.';

  @override
  String get emptyFavoritesSeries =>
      'Aún no tienes series favoritas.\nPulsa la ☆ de un póster para guardarla aquí.';

  @override
  String get transferTooltip => 'Pasar a otro dispositivo';

  @override
  String get resumeNeedsXtream => 'Añade tu cuenta Xtream para reanudar.';

  @override
  String get removeFromContinue => 'Quitar de \"Continuar viendo\"';

  @override
  String get movieLabel => 'Película';

  @override
  String get nowPlayingEmpty => 'Elige un canal de la lista para empezar';

  @override
  String get nowPlayingLabel => 'AHORA REPRODUCIENDO';

  @override
  String channelNumber(String number) {
    return 'Canal $number';
  }

  @override
  String get catchup => 'Catch-up';

  @override
  String catchupDays(int days) {
    return 'Catch-up $days d';
  }

  @override
  String get epgPending => 'Guía EPG (pendiente)';

  @override
  String get recentsClear => 'Borrar';

  @override
  String get recentsEmpty =>
      'Aún no has visto ningún canal.\nLos últimos que abras aparecerán aquí.';

  @override
  String get searchHint => 'Canales, películas y series';

  @override
  String get searchLoadingCatalogs =>
      'Cargando catálogo de películas y series…';

  @override
  String get favRemove => 'Quitar de favoritos';

  @override
  String get favAdd => 'Añadir a favoritos';

  @override
  String get favRemoved => 'Quitado de favoritos';

  @override
  String get favAdded => 'Añadido a favoritos';

  @override
  String get undo => 'Deshacer';

  @override
  String get syncTitle => 'Pasar a otro dispositivo';

  @override
  String get syncCodeCopied =>
      'Código copiado. Pégalo en el otro dispositivo, en Importar.';

  @override
  String get syncMerged => 'Listo: favoritos, recientes y progreso fusionados.';

  @override
  String get syncOtherAccount =>
      'Ese código es de otra cuenta. Añade la misma cuenta en este dispositivo y vuelve a intentarlo.';

  @override
  String get syncInvalidCode =>
      'El código no es válido. Cópialo entero desde el otro dispositivo.';

  @override
  String get syncStep1 => '1. En este dispositivo';

  @override
  String get syncStep1Desc =>
      'Copia un código con tus favoritos, canales recientes y películas a medias.';

  @override
  String get syncCopyCode => 'Copiar código';

  @override
  String get syncStep2 => '2. En el otro dispositivo';

  @override
  String get syncStep2Desc =>
      'Con la misma cuenta añadida, pega aquí el código.';

  @override
  String get syncPaste => 'Pegar';

  @override
  String get syncImport => 'Importar';

  @override
  String volumePercent(int percent) {
    return 'Volumen $percent%';
  }

  @override
  String get muted => 'Silenciado';

  @override
  String playerNow(String now) {
    return 'Ahora: $now';
  }

  @override
  String playerNowNext(String now, String next) {
    return 'Ahora: $now  ·  Después: $next';
  }

  @override
  String get programProgress => 'Progreso del programa';

  @override
  String get liveBadge => 'EN VIVO';

  @override
  String get rewind10 => 'Retroceder 10 s (←)';

  @override
  String get forward10 => 'Avanzar 10 s (→)';

  @override
  String get pauseTip => 'Pausar (Espacio)';

  @override
  String get playTip => 'Reproducir (Espacio)';

  @override
  String get unmuteTip => 'Activar sonido (M)';

  @override
  String get muteTip => 'Silenciar (M)';

  @override
  String get volumeLabel => 'Volumen';

  @override
  String get aspectRatio => 'Relación de aspecto';

  @override
  String get fullscreenTip => 'Pantalla completa (F)';

  @override
  String get trackAuto => 'Automático';

  @override
  String get trackOff => 'Desactivados';

  @override
  String trackN(int n) {
    return 'Pista $n';
  }

  @override
  String get audioAndSubtitles => 'Audio y subtítulos';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Subtítulos';

  @override
  String get playerNoChannel => 'Reproductor sin canal';

  @override
  String playerPlaying(String name) {
    return 'Reproduciendo $name';
  }

  @override
  String get playbackReconnecting => 'Reconectando…';

  @override
  String get playbackTryingFormat => 'Probando otro formato…';

  @override
  String get playbackOpenFailed =>
      'No se pudo abrir este contenido. Puede estar caído en tu proveedor.';

  @override
  String get tabUrl => 'URL M3U';

  @override
  String get tabFile => 'Archivo';

  @override
  String get fieldListUrl => 'URL de la lista';

  @override
  String get addList => 'Añadir lista';

  @override
  String get pickFileHint => 'Selecciona un archivo .m3u / .m3u8 de tu equipo.';

  @override
  String get pickFile => 'Elegir archivo';

  @override
  String get fieldServer => 'Servidor (http://host:puerto)';

  @override
  String get fieldUser => 'Usuario';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get connect => 'Conectar';

  @override
  String get errUrlInvalid => 'Introduce una URL completa (http:// o https://)';

  @override
  String get errFillXtream => 'Rellena servidor, usuario y contraseña';

  @override
  String get settingsSource => 'FUENTE';

  @override
  String get settingsLanguage => 'IDIOMA';

  @override
  String get noSavedSource => 'No hay ninguna fuente guardada.';

  @override
  String channelsCount(int count) {
    return '$count canales';
  }

  @override
  String get settingsStoredNote =>
      'Se guarda en este equipo y se carga sola al abrir la app. Las credenciales se almacenan cifradas por el sistema.';

  @override
  String get changeSource => 'Cambiar fuente';

  @override
  String get deleteSource => 'Eliminar fuente';

  @override
  String get deleteSourceTitle => '¿Eliminar la fuente?';

  @override
  String get deleteSourceBody =>
      'Se borrarán de este equipo la lista guardada y, si la hay, la cuenta Xtream. Tendrás que volver a añadirla para ver canales, películas y series.';

  @override
  String continueAt(String time) {
    return 'Continuar · $time';
  }

  @override
  String get fromStart => 'Desde el principio';

  @override
  String get play => 'Reproducir';

  @override
  String get noPlot => 'Sin sinopsis disponible.';

  @override
  String seasonEpisode(int season, int number) {
    return 'Temporada $season · Episodio $number';
  }

  @override
  String episodeName(String series, int season, int number) {
    return '$series · T$season E$number';
  }

  @override
  String seasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temporadas',
      one: '1 temporada',
    );
    return '$_temp0';
  }

  @override
  String continueEpisode(int season, int number, String time) {
    return 'Continuar T$season E$number · $time';
  }

  @override
  String episodesLoadError(String error) {
    return 'No se pudieron cargar los episodios: $error';
  }

  @override
  String get noEpisodes => 'Esta serie no tiene episodios disponibles.';

  @override
  String seasonN(int n) {
    return 'Temporada $n';
  }

  @override
  String episodeN(int n) {
    return 'Episodio $n';
  }

  @override
  String get episodeProgress => 'Progreso del episodio';

  @override
  String get castLabel => 'Reparto';

  @override
  String get directorLabel => 'Dirección';

  @override
  String mediaRequiresXtream(String title) {
    return '$title requiere una cuenta Xtream Codes.\nLas listas M3U solo traen canales en vivo.';
  }

  @override
  String get addXtreamAccount => 'Añadir cuenta Xtream';

  @override
  String mediaLoading(String title) {
    return 'Cargando catálogo de $title…';
  }

  @override
  String catalogLoadError(String error) {
    return 'No se pudo cargar el catálogo:\n$error';
  }

  @override
  String mediaSearchHint(String title) {
    return 'Buscar en $title';
  }

  @override
  String get noResults => 'Sin resultados';

  @override
  String noResultsFor(String query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get castTooltip => 'Emitir a Chromecast';

  @override
  String castTooltipActive(String device) {
    return 'Emitiendo en $device';
  }

  @override
  String castActive(String device) {
    return 'Emitiendo en $device.';
  }

  @override
  String get castSearching => 'Buscando dispositivos…';

  @override
  String get castNone =>
      'No se ha encontrado ningún Chromecast. Comprueba que está encendido y en la misma red Wi-Fi.';

  @override
  String get castStop => 'Dejar de emitir';

  @override
  String get errInvalidResponse =>
      'Respuesta inválida: credenciales o servidor incorrectos';

  @override
  String errInactiveAccount(String status) {
    return 'Cuenta no activa ($status)';
  }

  @override
  String errCannotConnect(String host) {
    return 'No se pudo conectar con $host';
  }

  @override
  String errHttp(int code) {
    return 'El servidor respondió HTTP $code';
  }

  @override
  String errDownload(String detail) {
    return 'No se pudo descargar la lista: $detail';
  }

  @override
  String get errFileMissing => 'El archivo ya no existe';
}
