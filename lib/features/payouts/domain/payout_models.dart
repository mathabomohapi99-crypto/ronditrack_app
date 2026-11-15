// NEW 10.3: one line of the payout order, shaped like the API's answer (money is Cents, status is an enum)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';

part 'payout_models.freezed.dart';

@freezed
abstract class PayoutEntry with _$PayoutEntry {
  const factory PayoutEntry({
    required String id,
    required String memberName,
    required int position,
    required Cents amount,
    required DateTime payoutDate,
    required PayoutStatus status,
  }) = _PayoutEntry;
}
