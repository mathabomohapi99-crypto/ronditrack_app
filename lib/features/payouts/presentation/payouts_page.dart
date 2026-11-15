// NEW 10.3: rotation and payouts. Shows the order EXACTLY as the server sent it: no sorting, no counting, no "who is next" logic here
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/theme/status_chip.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/payouts/domain/payout_labels.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';
import 'package:ronditrack/features/payouts/presentation/payout_providers.dart';
import 'package:ronditrack/features/stokvels/domain/actions.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';
import 'package:ronditrack/features/stokvels/presentation/not_found_view.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvel_card.dart';

class PayoutsPage extends ConsumerWidget {
  const PayoutsPage({
    required this.stokvelId,
    required this.cycleId,
    super.key,
  });
  final String stokvelId;
  final String cycleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(
      ref.watch(payoutOrderProvider(stokvelId, cycleId)),
      isEmpty: (order) => order.isEmpty,
    );
    // A cycle this person cannot see is "not found": the same screen as a missing one
    if (view case ViewFailure(:final error) when error is NotFoundException) {
      return const NotFoundView();
    }
    return Scaffold(
      key: const Key('payoutsPage'),
      appBar: AppBar(title: const Text('Rotation and payouts')),
      body: switch (view) {
        ViewLoading() => const LoadingView(),
        ViewEmpty() => const MessageView(
          'No payout order has been set for this cycle yet.',
        ),
        ViewData(:final data) => _Order(stokvelId: stokvelId, entries: data),
        ViewFailure() => RetryView(
          message: 'Could not load the payouts.',
          onRetry: () =>
              ref.invalidate(payoutOrderProvider(stokvelId, cycleId)),
        ),
      },
    );
  }
}

class _Order extends ConsumerWidget {
  const _Order({required this.stokvelId, required this.entries});
  final String stokvelId;
  final List<PayoutEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The role comes from THIS stokvel's membership and the 10.1 actions match, never from the user
    final detail = dataOf(ref.watch(stokvelDetailProvider(stokvelId)));
    final canRecord =
        detail != null &&
        actionsFor(detail).contains(StokvelAction.recordPayout);
    return ListView(
      key: const Key('payoutList'),
      padding: const EdgeInsets.all(16),
      children: [
        if (detail != null) Text('Your role here: ${roleLabel(detail.role)}'),
        const SizedBox(height: 8),
        for (final entry in entries) _PayoutCard(entry: entry),
        if (canRecord) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('recordPayoutButton'),
            onPressed: () {},
            child: Text(actionLabel(StokvelAction.recordPayout)),
          ),
        ],
      ],
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.entry});
  final PayoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    final scheme = Theme.of(context).colorScheme;
    // Only styling: the SERVER says which entry is Next, the card just makes it stand out
    final isNext = entry.status == PayoutStatus.next;
    return Card(
      key: Key('payout-${entry.id}'),
      color: isNext ? scheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Position ${entry.position}'),
            Text(
              entry.memberName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(formatRand(entry.amount)),
            Text('Payout date: ${formatDate(entry.payoutDate)}'),
            const SizedBox(height: 8),
            StatusChip(
              label: payoutStatusLabel(entry.status),
              tone: colors.forPayout(entry.status),
            ),
          ],
        ),
      ),
    );
  }
}
