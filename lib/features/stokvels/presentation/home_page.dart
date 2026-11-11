// NEW: Home screen: four states via exhaustive switch; one card per stokvel; pull to refresh
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/presentation/detail_page.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';

String _date(DateTime? d) => d == null
    ? 'none yet'
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(currentPersonaProvider);
    final view = toViewState(
      ref.watch(homeProvider),
      isEmpty: (l) => l.isEmpty,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('My stokvels'),
        actions: [
          PopupMenuButton<Persona>(
            key: const Key('personaPicker'),
            tooltip: 'Switch demo person',
            icon: const Icon(Icons.person),
            onSelected: (p) =>
                ref.read(currentPersonaProvider.notifier).select(p),
            itemBuilder: (_) => [
              for (final p in Persona.values)
                PopupMenuItem(value: p, child: Text(p.displayName)),
            ],
          ),
        ],
      ),
      body: switch (view) {
        ViewLoading() => const Center(
          child: CircularProgressIndicator(key: Key('loading')),
        ),
        ViewEmpty() => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${persona.displayName} is not in any stokvels yet. Ask a Treasurer for an invite link, or start your own.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        ViewData(:final data) => RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: ListView(
            children: [for (final e in data) _Card(entry: e, all: data)],
          ),
        ),
        ViewFailure() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your stokvels.'),
              FilledButton(
                onPressed: () => ref.invalidate(homeProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _Card extends StatelessWidget {
  const new({required this.entry, required this.all});
  final HomeEntry entry;
  final List<HomeEntry> all;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(entry.name),
      subtitle: Text(
        'Your role: ${roleLabel(entry.role)}\nPaid ${formatRand(entry.paid)} | Owed ${formatRand(entry.owed)} | Arrears ${formatRand(entry.arrears)}\nNext payout: ${_date(entry.nextPayout)}',
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StokvelDetailPage(
            initialId: entry.stokvelId,
            choices: [for (final e in all) (id: e.stokvelId, name: e.name)],
          ),
        ),
      ),
    ),
  );
}
