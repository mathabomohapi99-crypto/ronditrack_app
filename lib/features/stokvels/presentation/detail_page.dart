// NEW 10.2: stokvel detail from its address; "not found" for missing AND not-yours; switching = changing the address
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/theme/status_chip.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/stokvels/domain/actions.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';
import 'package:ronditrack/features/stokvels/presentation/not_found_view.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvel_card.dart';

class StokvelDetailPage extends ConsumerWidget {
  const StokvelDetailPage({
    required this.stokvelId,
    this.embedded = false,
    super.key,
  });
  final String stokvelId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(
      ref.watch(stokvelDetailProvider(stokvelId)),
      isEmpty: (d) => d.cycle == null,
    );
    if (view case ViewFailure(:final error) when error is NotFoundException) {
      return const NotFoundView();
    }
    final title = switch (view) {
      ViewData(:final data) => data.name,
      _ => 'Stokvel',
    };
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(title),
        actions: [if (!embedded) _StokvelPicker(currentId: stokvelId)],
      ),
      body: switch (view) {
        ViewLoading() => const LoadingView(),
        ViewEmpty() => const MessageView('No cycle yet in this stokvel.'),
        ViewData(:final data) => _Body(detail: data),
        ViewFailure() => RetryView(
          message: 'Could not load this stokvel.',
          onRetry: () => ref.invalidate(stokvelDetailProvider(stokvelId)),
        ),
      },
    );
  }
}

// The 10.1 picker, now navigation: choosing a stokvel changes the address
class _StokvelPicker extends ConsumerWidget {
  const _StokvelPicker({required this.currentId});
  final String currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = ref.watch(homeProvider).value ?? const <HomeEntry>[];
    return PopupMenuButton<String>(
      key: const Key('picker'),
      tooltip: 'Switch stokvel',
      icon: const Icon(Icons.swap_horiz),
      onSelected: (id) => StokvelRoute(id: id).go(context),
      itemBuilder: (_) => [
        for (final c in choices)
          PopupMenuItem(
            value: c.stokvelId,
            enabled: c.stokvelId != currentId,
            child: Text(c.name),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});
  final StokvelDetail detail;

  @override
  Widget build(BuildContext context) {
    final cycle = detail.cycle;
    final colors = context.statusColors;
    return ListView(
      key: const Key('detailList'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your role here: ${roleLabel(detail.role)}'),
        if (cycle != null) ...[
          const SizedBox(height: 8),
          Text('Cycle ${cycle.number}, due ${formatDate(cycle.dueDate)}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: cycleLabel(cycle.status),
              tone: colors.forCycle(cycle.status),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                CycleRoute(id: detail.stokvelId, cycleId: cycle.id).go(context),
            child: Text('Open cycle ${cycle.number}'),
          ),
        ],
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
        const Divider(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in actionsFor(detail))
              OutlinedButton(onPressed: () {}, child: Text(actionLabel(a))),
          ],
        ),
      ],
    );
  }
}
