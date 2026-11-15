// NEW 10.2: Stokvels tab: list only on narrow windows, list + detail side by side at 840 dp+ on ONE address
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/breakpoints.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/core/widgets/state_views.dart';
import 'package:ronditrack/features/stokvels/presentation/detail_page.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvel_card.dart';

class StokvelsScreen extends StatelessWidget {
  const StokvelsScreen({this.selectedId, super.key});
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final expanded = context.windowSize == WindowSize.expanded;
    final id = selectedId;
    return Scaffold(
      appBar: AppBar(title: const Text('Stokvels')),
      body: expanded
          ? Row(
              children: [
                SizedBox(width: 340, child: StokvelList(selectedId: id)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: id == null
                      ? const MessageView('Select a stokvel')
                      : StokvelDetailPage(stokvelId: id, embedded: true),
                ),
              ],
            )
          : const StokvelList(),
    );
  }
}

// Address /stokvels/:id: detail alone on narrow windows, master-detail on wide ones
class StokvelScreen extends StatelessWidget {
  const StokvelScreen({required this.stokvelId, super.key});
  final String stokvelId;

  @override
  Widget build(BuildContext context) =>
      context.windowSize == WindowSize.expanded
      ? StokvelsScreen(selectedId: stokvelId)
      : StokvelDetailPage(stokvelId: stokvelId);
}

class StokvelList extends ConsumerWidget {
  const StokvelList({this.selectedId, super.key});
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = toViewState(
      ref.watch(homeProvider),
      isEmpty: (l) => l.isEmpty,
    );
    return switch (view) {
      ViewLoading() => const LoadingView(),
      ViewEmpty() => const MessageView('You are not in any stokvels yet.'),
      ViewData(:final data) => ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final e in data)
            StokvelCard(
              entry: e,
              selected: e.stokvelId == selectedId,
              onTap: () => StokvelRoute(id: e.stokvelId).go(context),
            ),
        ],
      ),
      ViewFailure() => RetryView(
        message: 'Could not load your stokvels.',
        onRetry: () => ref.invalidate(homeProvider),
      ),
    };
  }
}
