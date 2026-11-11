// NEW: words for every status, one exhaustive switch each (status is never shown by colour alone)
import 'package:ronditrack/features/stokvels/domain/actions.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

String roleLabel(StokvelRole r) => switch (r) {
  StokvelRole.member => 'Member',
  StokvelRole.treasurer => 'Treasurer',
  StokvelRole.unknown => 'Unknown role',
};

String cycleLabel(CycleStatus s) => switch (s) {
  CycleStatus.open => 'Open',
  CycleStatus.closed => 'Closed',
  CycleStatus.paidOut => 'Paid out',
  CycleStatus.unknown => 'Unknown status',
};

String contributionLabel(ContributionStatus s) => switch (s) {
  ContributionStatus.pending => 'Pending',
  ContributionStatus.paid => 'Paid, awaiting confirmation',
  ContributionStatus.confirmed => 'Confirmed',
  ContributionStatus.unknown => 'Unknown status',
};

String actionLabel(StokvelAction a) => switch (a) {
  StokvelAction.pay => 'Pay',
  StokvelAction.uploadProof => 'Upload proof',
  StokvelAction.confirmContributions => 'Confirm contributions',
  StokvelAction.closeCycle => 'Close cycle',
  StokvelAction.recordPayout => 'Record payout',
};
