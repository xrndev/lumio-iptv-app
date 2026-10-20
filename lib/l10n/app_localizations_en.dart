// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navLive => 'Live';

  @override
  String get navMovies => 'Movies';

  @override
  String get navSeries => 'Series';

  @override
  String get navSearch => 'Search';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navRecents => 'Recents';

  @override
  String get navSettings => 'Settings';

  @override
  String get menuCollapse => 'Collapse menu';

  @override
  String get menuExpand => 'Expand menu';

  @override
  String get languageTooltip => 'Language';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonProgress => 'Progress';

  @override
  String get commonWatched => 'Watched';

  @override
  String get commonDelete => 'Delete';

  @override
  String get chipAllChannels => 'All';

  @override
  String get chipAllCategories => 'All';

  @override
  String sourceLoadError(String error) {
    return 'Couldn\'t load the source:\n$error';
  }

  @override
  String get tryAnotherSource => 'Try another source';

  @override
  String get addSourceHint =>
      'Add an M3U playlist, a file or an Xtream Codes account.';

  @override
  String get addSource => 'Add source';

  @override
  String get searchChannelHint => 'Search channel';

  @override
  String noticeInactive(String status) {
    return 'Your account isn\'t active ($status). Contact your provider.';
  }

  @override
  String get noticeExpired =>
      'Your subscription has expired. Renew it with your provider.';

  @override
  String get noticeExpiresToday => 'Your subscription expires today.';

  @override
  String noticeExpiresInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Your subscription expires in $days days.',
      one: 'Your subscription expires in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get singleConnectionHint =>
      'Your account allows only 1 connection: if you use it on another device, this channel may not open.';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get myFavorites => 'My favorites';

  @override
  String get kindChannels => 'Channels';

  @override
  String get favoritesNotInList =>
      'Your favorites aren\'t in the current list.';

  @override
  String get favoritesNotInCatalog =>
      'Your favorites aren\'t in the current catalog.';

  @override
  String get emptyFavoritesChannels =>
      'You have no favorite channels yet.\nTap the ☆ on any channel to save it here.';

  @override
  String get emptyFavoritesMovies =>
      'You have no favorite movies yet.\nTap the ☆ on a poster to save it here.';

  @override
  String get emptyFavoritesSeries =>
      'You have no favorite series yet.\nTap the ☆ on a poster to save it here.';

  @override
  String get transferTooltip => 'Move to another device';

  @override
  String get resumeNeedsXtream => 'Add your Xtream account to resume.';

  @override
  String get removeFromContinue => 'Remove from \"Continue watching\"';

  @override
  String get movieLabel => 'Movie';

  @override
  String get nowPlayingEmpty => 'Pick a channel from the list to start';

  @override
  String get nowPlayingLabel => 'NOW PLAYING';

  @override
  String channelNumber(String number) {
    return 'Channel $number';
  }

  @override
  String get catchup => 'Catch-up';

  @override
  String catchupDays(int days) {
    return 'Catch-up $days d';
  }

  @override
  String get epgPending => 'EPG guide (coming soon)';

  @override
  String get recentsClear => 'Clear';

  @override
  String get recentsEmpty =>
      'You haven\'t watched any channel yet.\nThe latest ones you open will show up here.';

  @override
  String get searchHint => 'Channels, movies and series';

  @override
  String get searchLoadingCatalogs => 'Loading movies and series catalog…';

  @override
  String get favRemove => 'Remove from favorites';

  @override
  String get favAdd => 'Add to favorites';

  @override
  String get favRemoved => 'Removed from favorites';

  @override
  String get favAdded => 'Added to favorites';

  @override
  String get undo => 'Undo';

  @override
  String get syncTitle => 'Move to another device';

  @override
  String get syncCodeCopied =>
      'Code copied. Paste it on the other device, under Import.';

  @override
  String get syncMerged => 'Done: favorites, recents and progress merged.';

  @override
  String get syncOtherAccount =>
      'That code belongs to another account. Add the same account on this device and try again.';

  @override
  String get syncInvalidCode =>
      'The code isn\'t valid. Copy it whole from the other device.';

  @override
  String get syncStep1 => '1. On this device';

  @override
  String get syncStep1Desc =>
      'Copy a code with your favorites, recent channels and half-watched movies.';

  @override
  String get syncCopyCode => 'Copy code';

  @override
  String get syncStep2 => '2. On the other device';

  @override
  String get syncStep2Desc =>
      'With the same account added, paste the code here.';

  @override
  String get syncPaste => 'Paste';

  @override
  String get syncImport => 'Import';

  @override
  String volumePercent(int percent) {
    return 'Volume $percent%';
  }

  @override
  String get muted => 'Muted';

  @override
  String playerNow(String now) {
    return 'Now: $now';
  }

  @override
  String playerNowNext(String now, String next) {
    return 'Now: $now  ·  Next: $next';
  }

  @override
  String get programProgress => 'Program progress';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get rewind10 => 'Back 10 s (←)';

  @override
  String get forward10 => 'Forward 10 s (→)';

  @override
  String get pauseTip => 'Pause (Space)';

  @override
  String get playTip => 'Play (Space)';

  @override
  String get unmuteTip => 'Unmute (M)';

  @override
  String get muteTip => 'Mute (M)';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get aspectRatio => 'Aspect ratio';

  @override
  String get fullscreenTip => 'Full screen (F)';

  @override
  String get trackAuto => 'Automatic';

  @override
  String get trackOff => 'Off';

  @override
  String trackN(int n) {
    return 'Track $n';
  }

  @override
  String get audioAndSubtitles => 'Audio and subtitles';

  @override
  String get audio => 'Audio';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get playerNoChannel => 'Player with no channel';

  @override
  String playerPlaying(String name) {
    return 'Playing $name';
  }

  @override
  String get playbackReconnecting => 'Reconnecting…';

  @override
  String get playbackTryingFormat => 'Trying another format…';

  @override
  String get playbackOpenFailed =>
      'Couldn\'t open this content. It may be down at your provider.';

  @override
  String get tabUrl => 'M3U URL';

  @override
  String get tabFile => 'File';

  @override
  String get fieldListUrl => 'Playlist URL';

  @override
  String get addList => 'Add playlist';

  @override
  String get pickFileHint => 'Select an .m3u / .m3u8 file from your device.';

  @override
  String get pickFile => 'Choose file';

  @override
  String get fieldServer => 'Server (http://host:port)';

  @override
  String get fieldUser => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get connect => 'Connect';

  @override
  String get errUrlInvalid => 'Enter a full URL (http:// or https://)';

  @override
  String get errFillXtream => 'Fill in server, username and password';

  @override
  String get settingsSource => 'SOURCE';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get noSavedSource => 'There is no saved source.';

  @override
  String channelsCount(int count) {
    return '$count channels';
  }

  @override
  String get settingsStoredNote =>
      'It is saved on this device and loads automatically when you open the app. Credentials are stored encrypted by the system.';

  @override
  String get changeSource => 'Change source';

  @override
  String get deleteSource => 'Delete source';

  @override
  String get deleteSourceTitle => 'Delete the source?';

  @override
  String get deleteSourceBody =>
      'The saved playlist and, if any, the Xtream account will be erased from this device. You\'ll have to add it again to see channels, movies and series.';

  @override
  String continueAt(String time) {
    return 'Continue · $time';
  }

  @override
  String get fromStart => 'From the beginning';

  @override
  String get play => 'Play';

  @override
  String get noPlot => 'No synopsis available.';

  @override
  String seasonEpisode(int season, int number) {
    return 'Season $season · Episode $number';
  }

  @override
  String episodeName(String series, int season, int number) {
    return '$series · S$season E$number';
  }

  @override
  String seasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }

  @override
  String continueEpisode(int season, int number, String time) {
    return 'Continue S$season E$number · $time';
  }

  @override
  String episodesLoadError(String error) {
    return 'Couldn\'t load the episodes: $error';
  }

  @override
  String get noEpisodes => 'This series has no episodes available.';

  @override
  String seasonN(int n) {
    return 'Season $n';
  }

  @override
  String episodeN(int n) {
    return 'Episode $n';
  }

  @override
  String get episodeProgress => 'Episode progress';

  @override
  String get castLabel => 'Cast';

  @override
  String get directorLabel => 'Director';

  @override
  String mediaRequiresXtream(String title) {
    return '$title requires an Xtream Codes account.\nM3U playlists only carry live channels.';
  }

  @override
  String get addXtreamAccount => 'Add Xtream account';

  @override
  String mediaLoading(String title) {
    return 'Loading $title catalog…';
  }

  @override
  String catalogLoadError(String error) {
    return 'Couldn\'t load the catalog:\n$error';
  }

  @override
  String mediaSearchHint(String title) {
    return 'Search $title';
  }

  @override
  String get noResults => 'No results';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get castTooltip => 'Cast to Chromecast';

  @override
  String castTooltipActive(String device) {
    return 'Casting to $device';
  }

  @override
  String castActive(String device) {
    return 'Casting to $device.';
  }

  @override
  String get castSearching => 'Looking for devices…';

  @override
  String get castNone =>
      'No Chromecast found. Check that it\'s on and connected to the same Wi-Fi network.';

  @override
  String get castStop => 'Stop casting';

  @override
  String get errInvalidResponse =>
      'Invalid response: wrong credentials or server';

  @override
  String errInactiveAccount(String status) {
    return 'Inactive account ($status)';
  }

  @override
  String errCannotConnect(String host) {
    return 'Couldn\'t connect to $host';
  }

  @override
  String errHttp(int code) {
    return 'The server answered HTTP $code';
  }

  @override
  String errDownload(String detail) {
    return 'Couldn\'t download the playlist: $detail';
  }

  @override
  String get errFileMissing => 'The file no longer exists';
}
