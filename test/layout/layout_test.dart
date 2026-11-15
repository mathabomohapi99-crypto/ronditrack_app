// NEW 10.2: layout tests: any RenderFlex overflow throws and fails the test
// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

import '../support/app_harness.dart';

void main() {
  const phone = Size(360, 640);

  for (final location in ['/', '/stokvels', '/stokvels/$ubuntuId']) {
    testWidgets('360x640 at 200% text, no overflow: $location', (tester) async {
      await pumpApp(
        tester,
        user: Persona.thandi,
        location: location,
        size: phone,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('360x640 at 200%: every action on detail is still reachable', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/$ubuntuId',
      size: phone,
      textScale: 2,
    );
    final scrollable = find.descendant(
      of: find.byKey(const Key('detailList')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Close cycle'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Close cycle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape: list and detail side by side on one address', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/$ubuntuId',
      size: const Size(1280, 800),
    );
    expect(find.text('Festive Grocery Club'), findsOneWidget);
    expect(find.text('Your role here: Treasurer'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
