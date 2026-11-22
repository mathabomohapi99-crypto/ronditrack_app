// NEW 11.2: the store, the cookie name and the session as providers (tests override the store with the in-memory one)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/core/network/dio_factory.dart';
import 'package:ronditrack/core/network/dio_provider.dart';
import 'package:ronditrack/core/session/access_token.dart';
import 'package:ronditrack/core/session/refresh_session.dart';
import 'package:ronditrack/core/session/token_store.dart';

part 'session_providers.g.dart';

@Riverpod(keepAlive: true)
RefreshTokenStore refreshTokenStore(Ref ref) => const SecureRefreshTokenStore();

/// main() overrides it from the flavour config: the name is never typed into code.
@Riverpod(keepAlive: true)
String refreshCookieName(Ref ref) =>
    throw UnimplementedError('main() overrides refreshCookieNameProvider');

@Riverpod(keepAlive: true)
RefreshSession refreshSession(Ref ref) {
  final bare = buildDio(
    baseUrl: ref.watch(apiBaseUrlProvider),
    readToken: () => null,
  );
  return RefreshSession(
    bare: bare,
    cookieName: ref.watch(refreshCookieNameProvider),
    store: ref.watch(refreshTokenStoreProvider),
    readAccess: () => ref.read(accessTokenProvider),
    writeAccess: ref.read(accessTokenProvider.notifier).set,
  );
}
