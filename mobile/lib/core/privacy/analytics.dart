// NEW 12.1: analytics events carry ids only, never a name, an email, a phone number or an amount
abstract interface class Analytics {
  void log(String event, {String? stokvelId, String? memberId});
}

class NoopAnalytics implements Analytics {
  const new();

  @override
  void log(String event, {String? stokvelId, String? memberId}) {}
}

/// Tests read every event and every field that would have left the phone.
class RecordingAnalytics implements Analytics {
  final events = <({String name, Map<String, String> fields})>[];

  @override
  void log(String event, {String? stokvelId, String? memberId}) => events.add((
    name: event,
    fields: {
      if (stokvelId != null) 'stokvelId': stokvelId,
      if (memberId != null) 'memberId': memberId,
    },
  ));
}
