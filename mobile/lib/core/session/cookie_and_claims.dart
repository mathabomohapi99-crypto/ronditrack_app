// NEW 11.2: read one cookie by name from several Set-Cookie lines; read token claims without checking the signature
import 'dart:convert';

/// The value of the cookie called [name], or null when it is not there.
String? cookieValue(List<String>? setCookieLines, String name) {
  for (final line in setCookieLines ?? const <String>[]) {
    final pair = line.split(';').first.trim();
    final i = pair.indexOf('=');
    if (i > 0 && pair.substring(0, i) == name) return pair.substring(i + 1);
  }
  return null;
}

/// Claims are for display only; the server is the one that checks the token.
Map<String, dynamic> readClaims(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return const {};
  try {
    final v = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return v is Map<String, dynamic> ? v : const {};
  } on FormatException {
    return const {};
  }
}
