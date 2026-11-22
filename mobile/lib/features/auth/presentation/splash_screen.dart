// NEW 11.2: shown while the one restore-refresh runs. Offline: still signed in, with Try again and Sign out
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/features/auth/application/auth_flow.dart';

class SplashScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authFlowProvider);
    final offline = status is Restoring && status.offline;
    return Scaffold(
      key: const Key('splash'),
      body: Center(
        child: offline
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'We could not reach RondiTrack. You are still signed in.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('try-again'),
                      onPressed: () =>
                          ref.read(authFlowProvider.notifier).restore(),
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      key: const Key('splash-sign-out'),
                      onPressed: () =>
                          ref.read(authFlowProvider.notifier).signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
