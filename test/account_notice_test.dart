import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/network/xtream_client.dart';
import 'package:lumio/l10n/app_localizations_en.dart';
import 'package:lumio/l10n/app_localizations_es.dart';
import 'package:lumio/l10n/error_text.dart';

void main() {
  final now = DateTime(2026, 10, 19, 12);
  XtreamAccount acc({String status = 'Active', DateTime? exp, int? max}) =>
      XtreamAccount(status: status, expiry: exp, maxConnections: max);

  test('sin avisos si falta mucho', () {
    expect(accountNotice(acc(exp: now.add(const Duration(days: 40))), now), isNull);
    expect(accountNotice(acc(), now), isNull);
  });
  test('avisa de caducidad próxima, hoy y caducada', () {
    final soon = accountNotice(acc(exp: now.add(const Duration(days: 3))), now)!;
    expect((soon.kind, soon.days), (AccountNoticeKind.expiresInDays, 3));
    expect(accountNotice(acc(exp: now.add(const Duration(days: 1, hours: 2))), now)!.days, 1);
    expect(accountNotice(acc(exp: now.add(const Duration(hours: 4))), now)!.kind,
        AccountNoticeKind.expiresToday);
    expect(accountNotice(acc(exp: now.subtract(const Duration(days: 1))), now)!.kind,
        AccountNoticeKind.expired);
  });
  test('cuenta inactiva', () {
    final n = accountNotice(acc(status: 'Disabled'), now)!;
    expect((n.kind, n.status), (AccountNoticeKind.inactive, 'Disabled'));
  });
  test('una sola conexión', () {
    expect(hasSingleConnection(acc(max: 1)), isTrue);
    expect(hasSingleConnection(acc(max: 2)), isFalse);
    expect(hasSingleConnection(null), isFalse);
  });
  test('los avisos se traducen en español e inglés', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();
    final soon = accountNotice(acc(exp: now.add(const Duration(days: 3))), now)!;
    expect(accountNoticeText(es, soon), contains('3 días'));
    expect(accountNoticeText(en, soon), contains('3 days'));
    final one = accountNotice(acc(exp: now.add(const Duration(days: 1, hours: 2))), now)!;
    expect(accountNoticeText(es, one), contains('1 día.'));
    expect(accountNoticeText(en, one), contains('1 day.'));
    final off = accountNotice(acc(status: 'Disabled'), now)!;
    expect(accountNoticeText(es, off), contains('no está activa'));
    expect(accountNoticeText(en, off), contains("isn't active"));
  });
}
