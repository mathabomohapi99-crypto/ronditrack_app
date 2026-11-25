import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/push/firebase_values.dart';

void main() {
  test('no values: push is off', () {
    expect(
      readFirebaseValues(apiKey: '', appId: '', senderId: '', projectId: ''),
      isNull,
    );
  });

  test('all four values: push is on', () {
    final v = readFirebaseValues(
      apiKey: 'a',
      appId: 'b',
      senderId: 'c',
      projectId: 'd',
    );
    expect(v?.projectId, 'd');
  });

  test('some values but not all: refuses to start', () {
    expect(
      () => readFirebaseValues(
        apiKey: 'a',
        appId: '',
        senderId: 'c',
        projectId: 'd',
      ),
      throwsA(isA<FirebaseConfigError>()),
    );
  });
}
