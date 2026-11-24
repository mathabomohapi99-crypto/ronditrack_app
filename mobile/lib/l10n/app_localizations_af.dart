// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class AppLocalizationsAf extends AppLocalizations {
  AppLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get payTitle => 'Betaal bydrae';

  @override
  String get payAmountLabel => 'Bedrag (rand)';

  @override
  String get payAmountHint => 'Byvoorbeeld 250,00';

  @override
  String get payButton => 'Betaal';

  @override
  String payPending(String amount) {
    return 'Hangend: $amount';
  }

  @override
  String get payErrorEmpty => 'Voer ’n bedrag in.';

  @override
  String get payErrorTooManyDecimals => 'Gebruik hoogstens twee desimale.';

  @override
  String get payErrorInvalid => 'Dit is nie ’n geldbedrag nie.';

  @override
  String get statusPaid => 'Betaal';

  @override
  String get statusPending => 'Hangend';

  @override
  String get statusLate => 'Laat';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lede',
      one: '1 lid',
      zero: 'Geen lede',
    );
    return '$_temp0';
  }

  @override
  String get languageLabel => 'Taal';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get languageAfrikaans => 'Afrikaans';

  @override
  String get languagePhone => 'Volg die foon';
}
