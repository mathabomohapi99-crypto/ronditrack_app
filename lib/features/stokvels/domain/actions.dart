// NEW: "what can I do here?" as ONE exhaustive record match, no wildcards, so a new status = compile error (Part 3)
// RULES ARE MY ASSUMPTION - compare with your API's rules and edit the arms.
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';

enum StokvelAction {
  pay,
  uploadProof,
  confirmContributions,
  closeCycle,
  recordPayout,
}

Set<StokvelAction> allowedActions(
  ({StokvelRole role, CycleStatus cycle, ContributionStatus mine}) c,
) => switch ((c.role, c.cycle, c.mine)) {
  (
    StokvelRole.member || StokvelRole.unknown,
    CycleStatus.open,
    ContributionStatus.pending,
  ) =>
    {StokvelAction.pay, StokvelAction.uploadProof},
  (
    StokvelRole.member || StokvelRole.unknown,
    CycleStatus.open,
    ContributionStatus.paid,
  ) =>
    {StokvelAction.uploadProof},
  (
    StokvelRole.member || StokvelRole.unknown,
    CycleStatus.open,
    ContributionStatus.confirmed || ContributionStatus.unknown,
  ) =>
    const <StokvelAction>{},
  (
    StokvelRole.member || StokvelRole.unknown,
    CycleStatus.closed || CycleStatus.paidOut || CycleStatus.unknown,
    ContributionStatus.pending ||
        ContributionStatus.paid ||
        ContributionStatus.confirmed ||
        ContributionStatus.unknown,
  ) =>
    const <StokvelAction>{},
  (StokvelRole.treasurer, CycleStatus.open, ContributionStatus.pending) => {
    StokvelAction.pay,
    StokvelAction.uploadProof,
    StokvelAction.confirmContributions,
    StokvelAction.closeCycle,
  },
  (StokvelRole.treasurer, CycleStatus.open, ContributionStatus.paid) => {
    StokvelAction.uploadProof,
    StokvelAction.confirmContributions,
    StokvelAction.closeCycle,
  },
  (
    StokvelRole.treasurer,
    CycleStatus.open,
    ContributionStatus.confirmed || ContributionStatus.unknown,
  ) =>
    {StokvelAction.confirmContributions, StokvelAction.closeCycle},
  (
    StokvelRole.treasurer,
    CycleStatus.closed,
    ContributionStatus.pending ||
        ContributionStatus.paid ||
        ContributionStatus.confirmed ||
        ContributionStatus.unknown,
  ) =>
    {StokvelAction.recordPayout},
  (
    StokvelRole.treasurer,
    CycleStatus.paidOut || CycleStatus.unknown,
    ContributionStatus.pending ||
        ContributionStatus.paid ||
        ContributionStatus.confirmed ||
        ContributionStatus.unknown,
  ) =>
    const <StokvelAction>{},
};

// Uses the role of THIS stokvel and my own contribution status in the current cycle
Set<StokvelAction> actionsFor(StokvelDetail d) {
  final cycle = d.cycle;
  if (cycle == null) return const <StokvelAction>{};
  final mine =
      d.contributions.where((c) => c.isMine).firstOrNull?.status ??
      ContributionStatus.pending;
  return allowedActions((role: d.role, cycle: cycle.status, mine: mine));
}
