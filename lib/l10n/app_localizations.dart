import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @navLive.
  ///
  /// In es, this message translates to:
  /// **'En vivo'**
  String get navLive;

  /// No description provided for @navMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get navMovies;

  /// No description provided for @navSeries.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get navSeries;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get navFavorites;

  /// No description provided for @navRecents.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get navRecents;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @menuCollapse.
  ///
  /// In es, this message translates to:
  /// **'Contraer menú'**
  String get menuCollapse;

  /// No description provided for @menuExpand.
  ///
  /// In es, this message translates to:
  /// **'Expandir menú'**
  String get menuExpand;

  /// No description provided for @languageTooltip.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTooltip;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @commonProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get commonProgress;

  /// No description provided for @commonWatched.
  ///
  /// In es, this message translates to:
  /// **'Visto'**
  String get commonWatched;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @chipAllChannels.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get chipAllChannels;

  /// No description provided for @chipAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get chipAllCategories;

  /// No description provided for @sourceLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la fuente:\n{error}'**
  String sourceLoadError(String error);

  /// No description provided for @tryAnotherSource.
  ///
  /// In es, this message translates to:
  /// **'Probar otra fuente'**
  String get tryAnotherSource;

  /// No description provided for @addSourceHint.
  ///
  /// In es, this message translates to:
  /// **'Añade una lista M3U, un archivo o una cuenta Xtream Codes.'**
  String get addSourceHint;

  /// No description provided for @addSource.
  ///
  /// In es, this message translates to:
  /// **'Añadir fuente'**
  String get addSource;

  /// No description provided for @searchChannelHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar canal'**
  String get searchChannelHint;

  /// No description provided for @noticeInactive.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no está activa ({status}). Contacta con tu proveedor.'**
  String noticeInactive(String status);

  /// No description provided for @noticeExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu suscripción ha caducado. Renueva con tu proveedor.'**
  String get noticeExpired;

  /// No description provided for @noticeExpiresToday.
  ///
  /// In es, this message translates to:
  /// **'Tu suscripción caduca hoy.'**
  String get noticeExpiresToday;

  /// No description provided for @noticeExpiresInDays.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Tu suscripción caduca en 1 día.} other{Tu suscripción caduca en {days} días.}}'**
  String noticeExpiresInDays(int days);

  /// No description provided for @singleConnectionHint.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta permite 1 sola conexión: si la usas en otro dispositivo, este canal puede no abrirse.'**
  String get singleConnectionHint;

  /// No description provided for @continueWatching.
  ///
  /// In es, this message translates to:
  /// **'Continuar viendo'**
  String get continueWatching;

  /// No description provided for @myFavorites.
  ///
  /// In es, this message translates to:
  /// **'Mis favoritos'**
  String get myFavorites;

  /// No description provided for @kindChannels.
  ///
  /// In es, this message translates to:
  /// **'Canales'**
  String get kindChannels;

  /// No description provided for @favoritesNotInList.
  ///
  /// In es, this message translates to:
  /// **'Tus favoritos no están en la lista actual.'**
  String get favoritesNotInList;

  /// No description provided for @favoritesNotInCatalog.
  ///
  /// In es, this message translates to:
  /// **'Tus favoritos no están en el catálogo actual.'**
  String get favoritesNotInCatalog;

  /// No description provided for @emptyFavoritesChannels.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes canales favoritos.\nPulsa la ☆ de cualquier canal para guardarlo aquí.'**
  String get emptyFavoritesChannels;

  /// No description provided for @emptyFavoritesMovies.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes películas favoritas.\nPulsa la ☆ de un póster para guardarla aquí.'**
  String get emptyFavoritesMovies;

  /// No description provided for @emptyFavoritesSeries.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes series favoritas.\nPulsa la ☆ de un póster para guardarla aquí.'**
  String get emptyFavoritesSeries;

  /// No description provided for @transferTooltip.
  ///
  /// In es, this message translates to:
  /// **'Pasar a otro dispositivo'**
  String get transferTooltip;

  /// No description provided for @resumeNeedsXtream.
  ///
  /// In es, this message translates to:
  /// **'Añade tu cuenta Xtream para reanudar.'**
  String get resumeNeedsXtream;

  /// No description provided for @removeFromContinue.
  ///
  /// In es, this message translates to:
  /// **'Quitar de \"Continuar viendo\"'**
  String get removeFromContinue;

  /// No description provided for @movieLabel.
  ///
  /// In es, this message translates to:
  /// **'Película'**
  String get movieLabel;

  /// No description provided for @nowPlayingEmpty.
  ///
  /// In es, this message translates to:
  /// **'Elige un canal de la lista para empezar'**
  String get nowPlayingEmpty;

  /// No description provided for @nowPlayingLabel.
  ///
  /// In es, this message translates to:
  /// **'AHORA REPRODUCIENDO'**
  String get nowPlayingLabel;

  /// No description provided for @channelNumber.
  ///
  /// In es, this message translates to:
  /// **'Canal {number}'**
  String channelNumber(String number);

  /// No description provided for @catchup.
  ///
  /// In es, this message translates to:
  /// **'Catch-up'**
  String get catchup;

  /// No description provided for @catchupDays.
  ///
  /// In es, this message translates to:
  /// **'Catch-up {days} d'**
  String catchupDays(int days);

  /// No description provided for @epgPending.
  ///
  /// In es, this message translates to:
  /// **'Guía EPG (pendiente)'**
  String get epgPending;

  /// No description provided for @recentsClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get recentsClear;

  /// No description provided for @recentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has visto ningún canal.\nLos últimos que abras aparecerán aquí.'**
  String get recentsEmpty;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Canales, películas y series'**
  String get searchHint;

  /// No description provided for @searchLoadingCatalogs.
  ///
  /// In es, this message translates to:
  /// **'Cargando catálogo de películas y series…'**
  String get searchLoadingCatalogs;

  /// No description provided for @favRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get favRemove;

  /// No description provided for @favAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir a favoritos'**
  String get favAdd;

  /// No description provided for @favRemoved.
  ///
  /// In es, this message translates to:
  /// **'Quitado de favoritos'**
  String get favRemoved;

  /// No description provided for @favAdded.
  ///
  /// In es, this message translates to:
  /// **'Añadido a favoritos'**
  String get favAdded;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Pasar a otro dispositivo'**
  String get syncTitle;

  /// No description provided for @syncCodeCopied.
  ///
  /// In es, this message translates to:
  /// **'Código copiado. Pégalo en el otro dispositivo, en Importar.'**
  String get syncCodeCopied;

  /// No description provided for @syncMerged.
  ///
  /// In es, this message translates to:
  /// **'Listo: favoritos, recientes y progreso fusionados.'**
  String get syncMerged;

  /// No description provided for @syncOtherAccount.
  ///
  /// In es, this message translates to:
  /// **'Ese código es de otra cuenta. Añade la misma cuenta en este dispositivo y vuelve a intentarlo.'**
  String get syncOtherAccount;

  /// No description provided for @syncInvalidCode.
  ///
  /// In es, this message translates to:
  /// **'El código no es válido. Cópialo entero desde el otro dispositivo.'**
  String get syncInvalidCode;

  /// No description provided for @syncStep1.
  ///
  /// In es, this message translates to:
  /// **'1. En este dispositivo'**
  String get syncStep1;

  /// No description provided for @syncStep1Desc.
  ///
  /// In es, this message translates to:
  /// **'Copia un código con tus favoritos, canales recientes y películas a medias.'**
  String get syncStep1Desc;

  /// No description provided for @syncCopyCode.
  ///
  /// In es, this message translates to:
  /// **'Copiar código'**
  String get syncCopyCode;

  /// No description provided for @syncStep2.
  ///
  /// In es, this message translates to:
  /// **'2. En el otro dispositivo'**
  String get syncStep2;

  /// No description provided for @syncStep2Desc.
  ///
  /// In es, this message translates to:
  /// **'Con la misma cuenta añadida, pega aquí el código.'**
  String get syncStep2Desc;

  /// No description provided for @syncPaste.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get syncPaste;

  /// No description provided for @syncImport.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get syncImport;

  /// No description provided for @volumePercent.
  ///
  /// In es, this message translates to:
  /// **'Volumen {percent}%'**
  String volumePercent(int percent);

  /// No description provided for @muted.
  ///
  /// In es, this message translates to:
  /// **'Silenciado'**
  String get muted;

  /// No description provided for @playerNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora: {now}'**
  String playerNow(String now);

  /// No description provided for @playerNowNext.
  ///
  /// In es, this message translates to:
  /// **'Ahora: {now}  ·  Después: {next}'**
  String playerNowNext(String now, String next);

  /// No description provided for @programProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso del programa'**
  String get programProgress;

  /// No description provided for @liveBadge.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get liveBadge;

  /// No description provided for @rewind10.
  ///
  /// In es, this message translates to:
  /// **'Retroceder 10 s (←)'**
  String get rewind10;

  /// No description provided for @forward10.
  ///
  /// In es, this message translates to:
  /// **'Avanzar 10 s (→)'**
  String get forward10;

  /// No description provided for @pauseTip.
  ///
  /// In es, this message translates to:
  /// **'Pausar (Espacio)'**
  String get pauseTip;

  /// No description provided for @playTip.
  ///
  /// In es, this message translates to:
  /// **'Reproducir (Espacio)'**
  String get playTip;

  /// No description provided for @unmuteTip.
  ///
  /// In es, this message translates to:
  /// **'Activar sonido (M)'**
  String get unmuteTip;

  /// No description provided for @muteTip.
  ///
  /// In es, this message translates to:
  /// **'Silenciar (M)'**
  String get muteTip;

  /// No description provided for @volumeLabel.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get volumeLabel;

  /// No description provided for @aspectRatio.
  ///
  /// In es, this message translates to:
  /// **'Relación de aspecto'**
  String get aspectRatio;

  /// No description provided for @fullscreenTip.
  ///
  /// In es, this message translates to:
  /// **'Pantalla completa (F)'**
  String get fullscreenTip;

  /// No description provided for @trackAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get trackAuto;

  /// No description provided for @trackOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivados'**
  String get trackOff;

  /// No description provided for @trackN.
  ///
  /// In es, this message translates to:
  /// **'Pista {n}'**
  String trackN(int n);

  /// No description provided for @audioAndSubtitles.
  ///
  /// In es, this message translates to:
  /// **'Audio y subtítulos'**
  String get audioAndSubtitles;

  /// No description provided for @audio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @subtitles.
  ///
  /// In es, this message translates to:
  /// **'Subtítulos'**
  String get subtitles;

  /// No description provided for @playerNoChannel.
  ///
  /// In es, this message translates to:
  /// **'Reproductor sin canal'**
  String get playerNoChannel;

  /// No description provided for @playerPlaying.
  ///
  /// In es, this message translates to:
  /// **'Reproduciendo {name}'**
  String playerPlaying(String name);

  /// No description provided for @playbackReconnecting.
  ///
  /// In es, this message translates to:
  /// **'Reconectando…'**
  String get playbackReconnecting;

  /// No description provided for @playbackTryingFormat.
  ///
  /// In es, this message translates to:
  /// **'Probando otro formato…'**
  String get playbackTryingFormat;

  /// No description provided for @playbackOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir este contenido. Puede estar caído en tu proveedor.'**
  String get playbackOpenFailed;

  /// No description provided for @tabUrl.
  ///
  /// In es, this message translates to:
  /// **'URL M3U'**
  String get tabUrl;

  /// No description provided for @tabFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get tabFile;

  /// No description provided for @fieldListUrl.
  ///
  /// In es, this message translates to:
  /// **'URL de la lista'**
  String get fieldListUrl;

  /// No description provided for @addList.
  ///
  /// In es, this message translates to:
  /// **'Añadir lista'**
  String get addList;

  /// No description provided for @pickFileHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un archivo .m3u / .m3u8 de tu equipo.'**
  String get pickFileHint;

  /// No description provided for @pickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get pickFile;

  /// No description provided for @fieldServer.
  ///
  /// In es, this message translates to:
  /// **'Servidor (http://host:puerto)'**
  String get fieldServer;

  /// No description provided for @fieldUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get fieldUser;

  /// No description provided for @fieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPassword;

  /// No description provided for @connect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get connect;

  /// No description provided for @errUrlInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce una URL completa (http:// o https://)'**
  String get errUrlInvalid;

  /// No description provided for @errFillXtream.
  ///
  /// In es, this message translates to:
  /// **'Rellena servidor, usuario y contraseña'**
  String get errFillXtream;

  /// No description provided for @settingsSource.
  ///
  /// In es, this message translates to:
  /// **'FUENTE'**
  String get settingsSource;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'IDIOMA'**
  String get settingsLanguage;

  /// No description provided for @noSavedSource.
  ///
  /// In es, this message translates to:
  /// **'No hay ninguna fuente guardada.'**
  String get noSavedSource;

  /// No description provided for @channelsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} canales'**
  String channelsCount(int count);

  /// No description provided for @settingsStoredNote.
  ///
  /// In es, this message translates to:
  /// **'Se guarda en este equipo y se carga sola al abrir la app. Las credenciales se almacenan cifradas por el sistema.'**
  String get settingsStoredNote;

  /// No description provided for @changeSource.
  ///
  /// In es, this message translates to:
  /// **'Cambiar fuente'**
  String get changeSource;

  /// No description provided for @deleteSource.
  ///
  /// In es, this message translates to:
  /// **'Eliminar fuente'**
  String get deleteSource;

  /// No description provided for @deleteSourceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la fuente?'**
  String get deleteSourceTitle;

  /// No description provided for @deleteSourceBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán de este equipo la lista guardada y, si la hay, la cuenta Xtream. Tendrás que volver a añadirla para ver canales, películas y series.'**
  String get deleteSourceBody;

  /// No description provided for @continueAt.
  ///
  /// In es, this message translates to:
  /// **'Continuar · {time}'**
  String continueAt(String time);

  /// No description provided for @fromStart.
  ///
  /// In es, this message translates to:
  /// **'Desde el principio'**
  String get fromStart;

  /// No description provided for @play.
  ///
  /// In es, this message translates to:
  /// **'Reproducir'**
  String get play;

  /// No description provided for @noPlot.
  ///
  /// In es, this message translates to:
  /// **'Sin sinopsis disponible.'**
  String get noPlot;

  /// No description provided for @seasonEpisode.
  ///
  /// In es, this message translates to:
  /// **'Temporada {season} · Episodio {number}'**
  String seasonEpisode(int season, int number);

  /// No description provided for @episodeName.
  ///
  /// In es, this message translates to:
  /// **'{series} · T{season} E{number}'**
  String episodeName(String series, int season, int number);

  /// No description provided for @seasonsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 temporada} other{{count} temporadas}}'**
  String seasonsCount(int count);

  /// No description provided for @continueEpisode.
  ///
  /// In es, this message translates to:
  /// **'Continuar T{season} E{number} · {time}'**
  String continueEpisode(int season, int number, String time);

  /// No description provided for @episodesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los episodios: {error}'**
  String episodesLoadError(String error);

  /// No description provided for @noEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Esta serie no tiene episodios disponibles.'**
  String get noEpisodes;

  /// No description provided for @seasonN.
  ///
  /// In es, this message translates to:
  /// **'Temporada {n}'**
  String seasonN(int n);

  /// No description provided for @episodeN.
  ///
  /// In es, this message translates to:
  /// **'Episodio {n}'**
  String episodeN(int n);

  /// No description provided for @episodeProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso del episodio'**
  String get episodeProgress;

  /// No description provided for @castLabel.
  ///
  /// In es, this message translates to:
  /// **'Reparto'**
  String get castLabel;

  /// No description provided for @directorLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get directorLabel;

  /// No description provided for @mediaRequiresXtream.
  ///
  /// In es, this message translates to:
  /// **'{title} requiere una cuenta Xtream Codes.\nLas listas M3U solo traen canales en vivo.'**
  String mediaRequiresXtream(String title);

  /// No description provided for @addXtreamAccount.
  ///
  /// In es, this message translates to:
  /// **'Añadir cuenta Xtream'**
  String get addXtreamAccount;

  /// No description provided for @mediaLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando catálogo de {title}…'**
  String mediaLoading(String title);

  /// No description provided for @catalogLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo:\n{error}'**
  String catalogLoadError(String error);

  /// No description provided for @mediaSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en {title}'**
  String mediaSearchHint(String title);

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @noResultsFor.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @castTooltip.
  ///
  /// In es, this message translates to:
  /// **'Emitir a Chromecast'**
  String get castTooltip;

  /// No description provided for @castTooltipActive.
  ///
  /// In es, this message translates to:
  /// **'Emitiendo en {device}'**
  String castTooltipActive(String device);

  /// No description provided for @castActive.
  ///
  /// In es, this message translates to:
  /// **'Emitiendo en {device}.'**
  String castActive(String device);

  /// No description provided for @castSearching.
  ///
  /// In es, this message translates to:
  /// **'Buscando dispositivos…'**
  String get castSearching;

  /// No description provided for @castNone.
  ///
  /// In es, this message translates to:
  /// **'No se ha encontrado ningún Chromecast. Comprueba que está encendido y en la misma red Wi-Fi.'**
  String get castNone;

  /// No description provided for @castStop.
  ///
  /// In es, this message translates to:
  /// **'Dejar de emitir'**
  String get castStop;

  /// No description provided for @errInvalidResponse.
  ///
  /// In es, this message translates to:
  /// **'Respuesta inválida: credenciales o servidor incorrectos'**
  String get errInvalidResponse;

  /// No description provided for @errInactiveAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta no activa ({status})'**
  String errInactiveAccount(String status);

  /// No description provided for @errCannotConnect.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con {host}'**
  String errCannotConnect(String host);

  /// No description provided for @errHttp.
  ///
  /// In es, this message translates to:
  /// **'El servidor respondió HTTP {code}'**
  String errHttp(int code);

  /// No description provided for @errDownload.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar la lista: {detail}'**
  String errDownload(String detail);

  /// No description provided for @errFileMissing.
  ///
  /// In es, this message translates to:
  /// **'El archivo ya no existe'**
  String get errFileMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
