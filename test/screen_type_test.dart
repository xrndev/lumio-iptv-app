import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_launcher/design_system/adaptive/screen_type.dart';

void main() {
  test('breakpoints Material 3', () {
    expect(ScreenType.fromWidth(360), ScreenType.compact);
    expect(ScreenType.fromWidth(599.9), ScreenType.compact);
    expect(ScreenType.fromWidth(600), ScreenType.medium);
    expect(ScreenType.fromWidth(839.9), ScreenType.medium);
    expect(ScreenType.fromWidth(840), ScreenType.expanded);
    expect(ScreenType.fromWidth(3440), ScreenType.expanded);
  });
}
