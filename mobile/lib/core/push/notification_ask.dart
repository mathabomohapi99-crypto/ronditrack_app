// NEW 12.2: when to ask about notifications. Once per phone, kept in settings (SharedPreferences), so sign-out does not reset it
import 'package:shared_preferences/shared_preferences.dart';

class NotificationAsk {
  const new(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'notification_asked';

  /// Only just after a payment is recorded, only when push is configured, and only the first time.
  bool shouldAsk({
    required bool pushConfigured,
    required bool justRecordedPayment,
  }) {
    if (!pushConfigured || !justRecordedPayment) return false;
    return !(_prefs.getBool(_key) ?? false);
  }

  /// Call after the person answers (yes or Not now): they are never asked again.
  Future<void> markAsked() => _prefs.setBool(_key, true);
}
