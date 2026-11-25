import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/app_version.dart';

void main() {
  test('the label says version, build and flavour', () {
    expect(
      versionLabel(version: '1.4.0', build: '37', flavor: 'staging'),
      'Version 1.4.0 (37) · staging',
    );
  });
}
