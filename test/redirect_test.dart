// NEW 10.2: the gate, tested with no widgets at all
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/redirect.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

void main() {
  test('signed out: sent to sign-in, remembering an in-app address', () {
    expect(
      redirectFor(user: null, uri: Uri.parse('/stokvels/abc')),
      '/sign-in?from=%2Fstokvels%2Fabc',
    );
  });
  test('signed out on /join/:code: remembered', () {
    expect(
      redirectFor(user: null, uri: Uri.parse('/join/ABC123')),
      '/sign-in?from=%2Fjoin%2FABC123',
    );
  });
  test('signed out on Home: plain sign-in', () {
    expect(redirectFor(user: null, uri: Uri.parse('/')), '/sign-in');
  });
  test('signed out on sign-in: stay', () {
    expect(redirectFor(user: null, uri: Uri.parse('/sign-in')), isNull);
  });
  test('signed in: no redirect', () {
    expect(
      redirectFor(user: Persona.thandi, uri: Uri.parse('/stokvels/abc')),
      isNull,
    );
  });
  test('signed in on sign-in with remembered /join/:code: go there', () {
    expect(
      redirectFor(
        user: Persona.thandi,
        uri: Uri.parse('/sign-in?from=%2Fjoin%2FABC123'),
      ),
      '/join/ABC123',
    );
  });
  test('signed in on sign-in, no from: Home', () {
    expect(redirectFor(user: Persona.thandi, uri: Uri.parse('/sign-in')), '/');
  });
  test('address from outside the app is never remembered', () {
    expect(
      redirectFor(
        user: Persona.thandi,
        uri: Uri.parse('/sign-in?from=https%3A%2F%2Fevil.example%2Fx'),
      ),
      '/',
    );
    expect(
      redirectFor(
        user: Persona.thandi,
        uri: Uri.parse('/sign-in?from=%2F%2Fevil.example'),
      ),
      '/',
    );
    expect(
      redirectFor(
        user: Persona.thandi,
        uri: Uri.parse('/sign-in?from=%2Fadmin'),
      ),
      '/',
    );
  });
}
