import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/network/xtream_client.dart';

void main() {
  final now = DateTime(2026, 10, 19, 12);
  XtreamAccount acc({String status = 'Active', DateTime? exp, int? max}) =>
      XtreamAccount(status: status, expiry: exp, maxConnections: max);

  test('sin avisos si falta mucho', () {
    expect(accountNotice(acc(exp: now.add(const Duration(days: 40))), now), isNull);
    expect(accountNotice(acc(), now), isNull);
  });
  test('avisa de caducidad próxima, hoy y caducada', () {
    expect(accountNotice(acc(exp: now.add(const Duration(days: 3))), now), contains('3 días'));
    expect(accountNotice(acc(exp: now.add(const Duration(days: 1, hours: 2))), now), contains('1 día.'));
    expect(accountNotice(acc(exp: now.add(const Duration(hours: 4))), now), contains('hoy'));
    expect(accountNotice(acc(exp: now.subtract(const Duration(days: 1))), now), contains('caducado'));
  });
  test('cuenta inactiva', () {
    expect(accountNotice(acc(status: 'Disabled'), now), contains('no está activa'));
  });
  test('pista de una sola conexión', () {
    expect(connectionHint(acc(max: 1)), isNotNull);
    expect(connectionHint(acc(max: 2)), isNull);
    expect(connectionHint(null), isNull);
  });
}
