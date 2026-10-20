import '../features/player/data/player_engine.dart';
import '../core/network/xtream_client.dart';
import '../core/errors.dart';
import 'app_localizations.dart';

/// Texto de un error para mostrarlo al usuario, en su idioma.
String localizedError(AppLocalizations l, Object e) {
  if (e is AppError) {
    return switch (e.code) {
      AppErrorCode.invalidResponse => l.errInvalidResponse,
      AppErrorCode.inactiveAccount => l.errInactiveAccount(e.arg),
      AppErrorCode.cannotConnect => l.errCannotConnect(e.arg),
      AppErrorCode.httpStatus => l.errHttp(int.tryParse(e.arg) ?? 0),
      AppErrorCode.downloadFailed => l.errDownload(e.arg),
      AppErrorCode.fileMissing => l.errFileMissing,
    };
  }
  return e.toString().replaceFirst(RegExp(r'^(Bad state|Exception|FormatException): '), '');
}

/// Texto de un aviso de cuenta Xtream.
String accountNoticeText(AppLocalizations l, AccountNotice n) => switch (n.kind) {
      AccountNoticeKind.inactive => l.noticeInactive(n.status),
      AccountNoticeKind.expired => l.noticeExpired,
      AccountNoticeKind.expiresToday => l.noticeExpiresToday,
      AccountNoticeKind.expiresInDays => l.noticeExpiresInDays(n.days),
    };

/// Texto del estado de reproducción (reconectando, otro formato, fallo).
String playbackNoticeText(AppLocalizations l, PlaybackNotice n) => switch (n) {
      PlaybackNotice.none => '',
      PlaybackNotice.reconnecting => l.playbackReconnecting,
      PlaybackNotice.tryingFormat => l.playbackTryingFormat,
      PlaybackNotice.openFailed => l.playbackOpenFailed,
    };
