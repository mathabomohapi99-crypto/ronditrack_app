// NEW 10.2: Home tab; no Navigator.push (typed route instead), no persona picker (identity = sign-in)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvel_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(
      ref.watch(homeProvider),
      isEmpty: (l) => l.isEmpty,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('My stokvels')),
      body: switch (view) {
        ViewLoading() => const LoadingView(),
        ViewEmpty() => const MessageView(
          'You are not in any stokvels yet. Ask a Treasurer for an invite link, or start your own.',
        ),
        ViewData(:final data) => RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            children: [
              for (final e in data)
                StokvelCard(
                  entry: e,
                  onTap: () => StokvelRoute(id: e.stokvelId).go(context),
                ),
            ],
          ),
        ),
        ViewFailure() => RetryView(
          message: 'Could not load your stokvels.',
          onRetry: () => ref.invalidate(homeProvider),
        ),
      },
    );
  }
}
