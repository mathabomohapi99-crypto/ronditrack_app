import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/push/push_route.dart';

void main() {
  test('a known type with plain ids opens that cycle', () {
    expect(
      routeForPush({
        'type': 'contribution_confirmed',
        'stokvelId': 's-1',
        'cycleId': 'c-9',
      }),
      '/stokvels/s-1/cycles/c-9',
    );
  });

  test('anything else goes nowhere', () {
    final bad = <Map<String, Object?>>[
      {'type': 'surprise', 'stokvelId': 's', 'cycleId': 'c'},
      {'type': 'cycle_closed', 'stokvelId': '../admin', 'cycleId': 'c'},
      {'type': 'cycle_closed', 'stokvelId': 's/1', 'cycleId': 'c'},
      {'type': 'cycle_closed', 'stokvelId': 's', 'cycleId': 'c?x=1'},
      {
        'type': 'cycle_closed',
        'stokvelId': 'https://evil.example',
        'cycleId': 'c',
      },
      {'type': 'cycle_closed', 'stokvelId': '', 'cycleId': 'c'},
      {'type': 'cycle_closed', 'stokvelId': 's'},
      {'type': 7, 'stokvelId': 's', 'cycleId': 'c'},
      <String, Object?>{},
    ];
    for (final d in bad) {
      expect(routeForPush(d), isNull, reason: '$d');
    }
  });
}
