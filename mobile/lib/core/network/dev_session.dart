import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/core/session/access_token.dart';

part 'dev_session.g.dart';

/// UPDATED 11.2: no --dart-define password anymore. The person signs in on the sign-in
/// screen; this only reads who the real access token says they are.
class DevSession {
  const new(this._readToken);

  final String? Function() _readToken;

  /// Kept so the API repositories still compile; the session interceptor does the real work.
  Future<void> ensure() async {}

  String? get userId {
    final jwt = _readToken();
    if (jwt == null) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final id =
          payload['sub'] ??
          payload['nameid'] ??
          payload['http://schemas.xmlsoap.org/ws/2005/08/identity/claims/nameidentifier'];
      return id is String ? id : null;
    } on Object {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
DevSession devSession(Ref ref) =>
    DevSession(() => ref.read(accessTokenProvider));
