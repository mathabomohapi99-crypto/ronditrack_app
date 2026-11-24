// NEW 12.1: runs on every Sentry event before it leaves the phone. Nothing about a member may get out
import 'package:sentry_flutter/sentry_flutter.dart';

/// The one tag that is kept: it lets support find the same failure in the API logs.
const correlationTag = 'correlation_id';

/// The signed-in member's name has no pattern, so it is passed in (set at sign-in, cleared at sign-out).
final scrubNames = <String>{};

final _query = RegExp(r'\?[^\s"]*');
final _jwt = RegExp(r'eyJ[\w\-]+\.[\w\-]+\.[\w\-]+');
final _bearer = RegExp(r'Bearer\s+[\w.\-]+', caseSensitive: false);
final _cookie = RegExp(r'refresh_token=[^;\s]+', caseSensitive: false);
final _email = RegExp(r'[\w.+\-]+@[\w\-]+(?:\.[\w\-]+)+');
final _file = RegExp(r'[\w\-]+\.(?:jpe?g|png|heic|pdf)', caseSensitive: false);
// en_ZA amounts: R 1 250,50 with ordinary or no-break spaces
final _amount = RegExp(r'\bR[ \u00A0]?\d[\d \u00A0]*(?:[,.]\d{1,2})?');
final _amountField = RegExp(
  r'''(amount\w*["']?\s*[:=]\s*)\d+''',
  caseSensitive: false,
);

String scrubText(String input, Set<String> names) {
  var t = input;
  t = t.replaceAll(_query, '?[query removed]');
  t = t.replaceAll(_jwt, '[token]');
  t = t.replaceAll(_bearer, '[token]');
  t = t.replaceAll(_cookie, '[token]');
  t = t.replaceAll(_email, '[email]');
  t = t.replaceAll(_file, '[file]');
  t = t.replaceAll(_amount, '[amount]');
  t = t.replaceAllMapped(_amountField, (m) => '${m[1]}[amount]');
  for (final name in names) {
    final parts = {name, ...name.split(RegExp(r'\s+'))};
    for (final part in parts) {
      if (part.trim().length < 3) continue;
      t = t.replaceAll(
        RegExp(RegExp.escape(part), caseSensitive: false),
        '[name]',
      );
    }
  }
  return t;
}

// Every string, wherever it hides (message, exceptions, breadcrumbs, tags, contexts, extra)
Object? _deep(Object? v, Set<String> names) => switch (v) {
  final String s => scrubText(s, names),
  final Map<dynamic, dynamic> m => <String, dynamic>{
    for (final e in m.entries) e.key.toString(): _deep(e.value, names),
  },
  final List<dynamic> l => <dynamic>[for (final x in l) _deep(x, names)],
  _ => v,
};

SentryEvent scrubEvent(SentryEvent e, {Set<String>? names}) {
  final n = names ?? scrubNames;
  final json = e.toJson();
  final tags = json['tags'];
  final correlation = tags is Map ? tags[correlationTag] : null;
  final clean = Map<String, dynamic>.from(_deep(json, n)! as Map);
  // No name, no email: only a constant
  if (json.containsKey('user'))
    clean['user'] = <String, dynamic>{'id': 'member'};
  final req = clean['request'];
  if (req is Map) {
    req
      ..remove('data')
      ..remove('cookies')
      ..remove('query_string');
    final headers = req['headers'];
    if (headers is Map) {
      headers.removeWhere(
        (k, _) =>
            {'authorization', 'cookie'}.contains(k.toString().toLowerCase()),
      );
    }
  }
  // The correlation id is the one thing that must survive
  if (correlation != null) {
    final t = Map<String, dynamic>.from((clean['tags'] as Map?) ?? {});
    t[correlationTag] = correlation;
    clean['tags'] = t;
  }
  return SentryEvent.fromJson(clean);
}
