// NEW 10.3: the words for each payout status, one exhaustive switch with NO wildcard (a new status will not compile until it has words)
import 'package:ronditrack/features/payouts/domain/payout_status.dart';

String payoutStatusLabel(PayoutStatus s) => switch (s) {
  PayoutStatus.paid => 'Paid out',
  PayoutStatus.next => 'Next to be paid',
  PayoutStatus.waiting => 'Waiting for turn',
  PayoutStatus.unknown => 'Unknown status',
};
