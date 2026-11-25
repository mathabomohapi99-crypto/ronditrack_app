import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/push/notification_ask.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<NotificationAsk> make() async {
    SharedPreferences.setMockInitialValues({});
    return NotificationAsk(await SharedPreferences.getInstance());
  }

  test('asks after the first payment', () async {
    final ask = await make();
    expect(
      ask.shouldAsk(pushConfigured: true, justRecordedPayment: true),
      isTrue,
    );
  });

  test('never at launch', () async {
    final ask = await make();
    expect(
      ask.shouldAsk(pushConfigured: true, justRecordedPayment: false),
      isFalse,
    );
  });

  test('never again after Not now', () async {
    final ask = await make();
    await ask.markAsked();
    expect(
      ask.shouldAsk(pushConfigured: true, justRecordedPayment: true),
      isFalse,
    );
  });

  test('not at all with push off', () async {
    final ask = await make();
    expect(
      ask.shouldAsk(pushConfigured: false, justRecordedPayment: true),
      isFalse,
    );
  });
}
