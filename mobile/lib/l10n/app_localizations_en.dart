// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get payTitle => 'Pay contribution';

  @override
  String get payAmountLabel => 'Amount (rands)';

  @override
  String get payAmountHint => 'For example 250,00';

  @override
  String get payButton => 'Pay';

  @override
  String get payClose => 'Close';

  @override
  String payPending(String amount) {
    return 'Pending: $amount';
  }

  @override
  String get payErrorEmpty => 'Enter an amount.';

  @override
  String get payErrorTooManyDecimals => 'Use at most two decimals.';

  @override
  String get payErrorInvalid => 'That is not an amount of money.';

  @override
  String get payDone => 'Payment sent.';

  @override
  String get payQueued => 'Saved. It will be sent when you have signal.';

  @override
  String payWaiting(int seconds) {
    return 'Too many attempts. Waiting $seconds seconds.';
  }

  @override
  String get payRefusedGeneric => 'The payment was refused.';

  @override
  String get payExpired =>
      'This payment waited too long and was not sent. Check your payments and pay again if you need to.';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusLate => 'Late';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
      zero: 'No members',
    );
    return '$_temp0';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAfrikaans => 'Afrikaans';

  @override
  String get languagePhone => 'Follow the phone';
}
