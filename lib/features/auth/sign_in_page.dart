// NEW 10.2: fake sign-in by email (one of the three seed personas). The router remembers where to go next
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/features/auth/auth_provider.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = ref.read(authProvider.notifier).signInWithEmail(_email.text);
    if (!ok) setState(() => _error = 'We do not know that email.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('signInPage'),
    appBar: AppBar(title: const Text('Sign in')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Demo emails: thandi.nkosi@example.com, sipho.dlamini@example.com, bongani.zulu@example.com',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('emailField'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'Email', errorText: _error),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('signInButton'),
          onPressed: _submit,
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}
