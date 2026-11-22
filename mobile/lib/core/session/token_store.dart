// NEW 11.2: where the refresh token lives, behind our own interface so tests can use memory
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class RefreshTokenStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  // The email is kept next to the token so a restored session knows who it is
  Future<String?> readEmail();
  Future<void> writeEmail(String email);
  Future<void> clear();
}

/// The real one: Android Keystore through flutter_secure_storage.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const new([this._s = const FlutterSecureStorage()]);

  final FlutterSecureStorage _s;

  @override
  Future<String?> readToken() => _s.read(key: 'refresh_token');
  @override
  Future<void> writeToken(String token) =>
      _s.write(key: 'refresh_token', value: token);
  @override
  Future<String?> readEmail() => _s.read(key: 'session_email');
  @override
  Future<void> writeEmail(String email) =>
      _s.write(key: 'session_email', value: email);
  @override
  Future<void> clear() async {
    await _s.delete(key: 'refresh_token');
    await _s.delete(key: 'session_email');
  }
}

/// The test one: nothing touches the phone.
class InMemoryRefreshTokenStore implements RefreshTokenStore {
  String? _token;
  String? _email;

  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String token) async => _token = token;
  @override
  Future<String?> readEmail() async => _email;
  @override
  Future<void> writeEmail(String email) async => _email = email;
  @override
  Future<void> clear() async {
    _token = null;
    _email = null;
  }
}
