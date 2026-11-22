// NEW 11.2: access token in memory, refresh token in the store, ONE refresh at a time
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ronditrack/core/session/cookie_and_claims.dart';
import 'package:ronditrack/core/session/token_store.dart';

enum RestoreResult { signedIn, signedOut, offline }

/// Thrown only when the refresh endpoint itself said 401 (or nothing is stored).
class SessionEnded implements Exception {
  const new();
}

/// What the sign-in screen shows.
class SignInException implements Exception {
  const new(this.message, {this.retryAfter});

  final String message;
  final Duration? retryAfter;
}

class RefreshSession {
  new({
    required this.bare,
    required this.cookieName,
    required this.store,
    required this.readAccess,
    required this.writeAccess,
    this.margin = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// A client WITHOUT the session interceptor: login, refresh, logout and retries use it,
  /// so a refresh can never wait on itself.
  final Dio bare;
  final String cookieName;
  final RefreshTokenStore store;
  final String? Function() readAccess;
  final void Function(String?) writeAccess;
  final Duration margin;
  final DateTime Function() _now;

  /// Called when the API refuses our refresh token: the app signs the person out.
  void Function()? onEnded;

  DateTime? _expiresAt;
  int _gen = 0; // bumps on sign-out so a late refresh is ignored
  Future<void>? _inflight;

  String? get accessToken => readAccess();

  bool get nearExpiry =>
      _expiresAt != null && _now().isAfter(_expiresAt!.subtract(margin));

  Future<void> login(String email, String password) async {
    final gen = _gen;
    try {
      final res = await bare.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = res.data ?? const <String, dynamic>{};
      final token = body['accessToken'];
      final cookie = cookieValue(res.headers['set-cookie'], cookieName);
      if (token is! String || cookie == null) {
        throw const SignInException('Something went wrong. Please try again.');
      }
      if (gen != _gen) return;
      _accept(body);
      await store.writeToken(cookie);
      await store.writeEmail(email);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429) {
        final secs =
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 60;
        throw SignInException(
          'Too many attempts. Please wait.',
          retryAfter: Duration(seconds: secs),
        );
      }
      // Never says WHICH of email or password was wrong
      if (code == 401 || code == 400) {
        throw const SignInException('Email and password do not match.');
      }
      throw const SignInException('We could not reach the server. Try again.');
    }
  }

  void _accept(Map<String, dynamic> body) {
    writeAccess(body['accessToken']! as String);
    final secs = body['expiresInSeconds'];
    _expiresAt = secs is num
        ? _now().add(Duration(seconds: secs.toInt()))
        : null;
  }

  /// SINGLE FLIGHT: everybody who needs a refresh waits for the same one.
  Future<void> refresh() =>
      _inflight ??= _doRefresh().whenComplete(() => _inflight = null);

  Future<void> _doRefresh() async {
    final stored = await store.readToken();
    if (stored == null) throw const SessionEnded();
    final gen = _gen;
    try {
      final res = await bare.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        // The cookie goes ONLY to refresh and logout, by hand
        options: Options(headers: {'Cookie': '$cookieName=$stored'}),
      );
      if (gen != _gen) {
        return; // signed out while we waited: sign nobody back in
      }
      final body = res.data ?? const <String, dynamic>{};
      if (body['accessToken'] is! String) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: 'Refresh answered without an access token',
        );
      }
      _accept(body);
      final rotated = cookieValue(res.headers['set-cookie'], cookieName);
      if (rotated != null) await store.writeToken(rotated);
    } on DioException catch (e) {
      if (gen != _gen) return;
      // ONLY the refresh endpoint's own 401 ends a session; 403/429/500/no answer never do
      if (e.response?.statusCode == 401) {
        _gen++;
        writeAccess(null);
        _expiresAt = null;
        await store.clear();
        onEnded?.call();
        throw const SessionEnded();
      }
      rethrow;
    }
  }

  /// One refresh on launch if a token is stored.
  Future<RestoreResult> restore() async {
    try {
      if (await store.readToken() == null) return RestoreResult.signedOut;
      await refresh();
      return RestoreResult.signedIn;
    } on SessionEnded {
      return RestoreResult.signedOut;
    } on DioException {
      return RestoreResult.offline; // no signal is not signed out
    } on Object {
      return RestoreResult.signedOut;
    }
  }

  /// Wipes memory and storage FIRST, then tells the API with a short timeout.
  /// Never depends on the answer.
  Future<void> signOut() async {
    _gen++;
    writeAccess(null);
    _expiresAt = null;
    String? stored;
    try {
      stored = await store.readToken();
    } on Object {
      stored = null;
    }
    await store.clear();
    if (stored != null) unawaited(_remoteLogout(stored));
  }

  Future<void> _remoteLogout(String stored) async {
    try {
      await bare.post<void>(
        '/api/v1/auth/logout',
        options: Options(
          headers: {'Cookie': '$cookieName=$stored'},
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
    } on Object {
      // ignored on purpose: sign-out never depends on the network
    }
  }
}

/// Goes on the app's main client only.
class SessionInterceptor extends Interceptor {
  new(this._s);

  final RefreshSession _s;

  @override
  Future<void> onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    try {
      // Refresh a little BEFORE the token expires, so no 401 happens at all
      if (_s.accessToken != null && _s.nearExpiry) await _s.refresh();
    } on Object {
      // not fatal here: the request goes out and a 401 is handled in onError
    }
    o.extra['sentWith'] = _s.accessToken; // which token this request used
    h.next(o);
  }

  @override
  Future<void> onError(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    if (e.response?.statusCode != 401 ||
        o.extra['retried'] == true ||
        o.extra['sentWith'] == null) {
      return h.next(e);
    }
    try {
      // Refresh only if the token this request used is STILL the current one.
      // If it was already replaced, just retry with the new one (never a second refresh).
      if (_s.accessToken == o.extra['sentWith']) await _s.refresh();
      final t = _s.accessToken;
      if (t == null) return h.next(e);
      o.headers['Authorization'] = 'Bearer $t';
      o.extra['retried'] = true; // retry ONCE
      h.resolve(await _s.bare.fetch<dynamic>(o));
    } on SessionEnded {
      h.next(e);
    } on DioException catch (err) {
      h.next(err);
    }
  }
}
