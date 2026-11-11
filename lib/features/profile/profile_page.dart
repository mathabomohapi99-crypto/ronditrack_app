// NEW 10.2: Profile tab: who is signed in + sign out
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/features/auth/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            persona?.displayName ?? 'Signed out',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (persona != null) Text(emailForPersona(persona)),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('signOutButton'),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
