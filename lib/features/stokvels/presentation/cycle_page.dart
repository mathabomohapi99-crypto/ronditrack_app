// NEW 10.2: a cycle under its stokvel; a cycle from ANOTHER stokvel is "not found" just like a missing one
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/theme/status_chip.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';
import 'package:ronditrack/features/stokvels/presentation/not_found_view.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvel_card.dart';

class CyclePage extends ConsumerWidget {
  const CyclePage({required this.stokvelId, required this.cycleId, super.key});
  final String stokvelId;
  final String cycleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(ref.watch(stokvelDetailProvider(stokvelId)));
    return switch (view) {
      ViewLoading() => Scaffold(
        appBar: AppBar(title: const Text('Cycle')),
        body: const LoadingView(),
      ),
      ViewEmpty() => const NotFoundView(),
      ViewFailure(:final error) =>
        error is NotFoundException
            ? const NotFoundView()
            : Scaffold(
                appBar: AppBar(title: const Text('Cycle')),
                body: RetryView(
                  message: 'Could not load this cycle.',
                  onRetry: () =>
                      ref.invalidate(stokvelDetailProvider(stokvelId)),
                ),
              ),
      ViewData(:final data) => _content(data),
    };
  }

  Widget _content(StokvelDetail detail) {
    final cycle = detail.cycle;
    if (cycle == null || cycle.id != cycleId) return const NotFoundView();
    return _CycleBody(detail: detail, cycle: cycle);
  }
}

class _CycleBody extends StatelessWidget {
  const _CycleBody({required this.detail, required this.cycle});
  final StokvelDetail detail;
  final CycleInfo cycle;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    return Scaffold(
      key: const Key('cyclePage'),
      appBar: AppBar(title: Text('Cycle ${cycle.number}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(detail.name, style: Theme.of(context).textTheme.titleMedium),
          Text('Due ${formatDate(cycle.dueDate)}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: cycleLabel(cycle.status),
              tone: colors.forCycle(cycle.status),
            ),
          ),
          const Divider(),
          for (final c in detail.contributions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.memberName),
                  Text(formatRand(c.amount)),
                  const SizedBox(height: 4),
                  StatusChip(
                    label: contributionLabel(c.status),
                    tone: colors.forContribution(c.status),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
