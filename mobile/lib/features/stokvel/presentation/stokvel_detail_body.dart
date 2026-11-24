import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/routes.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/core/format_date.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/features/payments/application/outbox_providers.dart';
import 'package:ronditrack/features/payments/presentation/pay_form.dart';
import 'package:ronditrack/features/stokvel/domain/actions.dart';
import 'package:ronditrack/features/stokvel/domain/enums.dart';
import 'package:ronditrack/features/stokvel/domain/models.dart';
import 'package:ronditrack/features/stokvel/presentation/contribution_tile.dart';
import 'package:ronditrack/features/stokvel/presentation/labels.dart';
import 'package:ronditrack/features/stokvel/presentation/status_chips.dart';
import 'package:ronditrack/l10n/app_localizations.dart';

// UPDATED 11.3: ConsumerWidget so it can watch the outbox
class StokvelDetailBody extends ConsumerWidget {
  const new({required this.detail, super.key});

  final StokvelDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = detail.cycle;
    final actions = allowedActions((
      role: detail.role,
      cycle: cycle?.status ?? CycleStatus.unknown,
      mine: detail.myContribution,
    ));
    final waiting =
        (ref.watch(pendingPaymentsProvider).value ?? const <OutboxPayment>[])
            .where((p) => cycle != null && p.cycleId == cycle.id)
            .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          detail.stokvel.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Your role: ${roleLabel(detail.role)}'),
        if (cycle != null)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Cycle ${cycle.number}, due ${formatDate(cycle.dueDate)}'),
              CycleStatusChip(status: cycle.status),
            ],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final a in StokvelAction.values)
              if (actions.contains(a))
                FilledButton.tonal(
                  onPressed: a == StokvelAction.pay && cycle != null
                      ? () => showDialog<void>(
                          context: context,
                          builder: (_) => PayForm(
                            stokvelId: detail.stokvel.id,
                            cycleId: cycle.id,
                          ),
                        )
                      : () {},
                  child: Text(actionLabel(a)),
                ),
          ],
        ),
        // A waiting payment is shown beside the server's numbers, marked pending, never added in
        for (final p in waiting)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(
              AppLocalizations.of(context)
                  .payPending(formatRands(Cents(p.amountCents))),
            ),
          ),
        if (cycle != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('View cycle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CycleRoute(
              id: detail.stokvel.id,
              cycleId: cycle.id,
            ).go(context),
          ),
        const Divider(height: 32),
        for (final c in detail.contributions) ContributionTile(contribution: c),
      ],
    );
  }
}
