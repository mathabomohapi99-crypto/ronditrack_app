// NEW 10.2: Activity tab with the four states
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/activity/activity_provider.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(
      ref.watch(activityProvider),
      isEmpty: (l) => l.isEmpty,
    );
    return Scaffold(
      key: const Key('activityPage'),
      appBar: AppBar(title: const Text('Activity')),
      body: switch (view) {
        ViewLoading() => const LoadingView(),
        ViewEmpty() => const MessageView('No activity yet.'),
        ViewData(:final data) => ListView(
          children: [for (final line in data) ListTile(title: Text(line))],
        ),
        ViewFailure() => RetryView(
          message: 'Could not load activity.',
          onRetry: () => ref.invalidate(activityProvider),
        ),
      },
    );
  }
}
