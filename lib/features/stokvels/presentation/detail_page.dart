// NEW: stokvel detail with a stokvel picker in the app bar; family provider = never the wrong stokvel for a frame
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/features/stokvels/domain/actions.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';

class StokvelDetailPage extends ConsumerStatefulWidget {
  const new({required this.initialId, required this.choices, super.key});
  final String initialId;
  final List<({String id, String name})> choices;

  @override
  ConsumerState<StokvelDetailPage> createState() => _StokvelDetailPageState();
}

class _StokvelDetailPageState extends ConsumerState<StokvelDetailPage> {
  late String _id = widget.initialId;

  @override
  Widget build(BuildContext context) {
    final name =
        widget.choices.where((c) => c.id == _id).firstOrNull?.name ?? 'Stokvel';
    final view = toViewState(
      ref.watch(stokvelDetailProvider(_id)),
      isEmpty: (d) => d.cycle == null,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          PopupMenuButton<String>(
            key: const Key('picker'),
            tooltip: 'Switch stokvel',
            onSelected: (id) => setState(() => _id = id),
            itemBuilder: (_) => [
              for (final c in widget.choices)
                PopupMenuItem(value: c.id, child: Text(c.name)),
            ],
          ),
        ],
      ),
      body: switch (view) {
        ViewLoading() => const Center(
          child: CircularProgressIndicator(key: Key('loading')),
        ),
        ViewEmpty() => const Center(
          child: Text('No cycle yet in this stokvel.'),
        ),
        ViewData(:final data) => _Body(detail: data),
        ViewFailure(:final error) => Center(
          child: error is NotFoundException
              ? const Text(
                  'Stokvel not found',
                ) // identical for missing AND not-yours
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load this stokvel.'),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(stokvelDetailProvider(_id)),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
        ),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const new({required this.detail});
  final StokvelDetail detail;

  @override
  Widget build(BuildContext context) {
    final cycle = detail.cycle;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your role here: ${roleLabel(detail.role)}'),
        if (cycle != null)
          Text('Cycle ${cycle.number}: ${cycleLabel(cycle.status)}'),
        const Divider(),
        for (final c in detail.contributions)
          ListTile(
            title: Text(c.memberName),
            subtitle: Text(
              '${formatRand(c.amount)} | ${contributionLabel(c.status)}',
            ),
          ),
        const Divider(),
        Wrap(
          spacing: 8,
          children: [
            for (final a in actionsFor(detail))
              OutlinedButton(onPressed: () {}, child: Text(actionLabel(a))),
          ],
        ),
      ],
    );
  }
}
