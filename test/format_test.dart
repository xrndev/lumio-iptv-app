import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/util/format.dart';

void main() {
  test('formatClock', () {
    expect(formatClock(Duration.zero), '0:00');
    expect(formatClock(const Duration(seconds: 9)), '0:09');
    expect(formatClock(const Duration(minutes: 42, seconds: 10)), '42:10');
    expect(formatClock(const Duration(hours: 1, minutes: 5, seconds: 30)), '1:05:30');
    expect(formatClock(const Duration(hours: 12)), '12:00:00');
    expect(formatClock(const Duration(seconds: -5)), '0:00');
  });
}
