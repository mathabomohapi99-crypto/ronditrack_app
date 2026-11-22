import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/session/refresh_session.dart';
import 'package:ronditrack/core/session/session.dart';
import 'package:ronditrack/features/auth/application/auth_flow.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const new({this.from, super.key});

  final String? from;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  int _wait = 0; // seconds left from Retry-After
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // The button stays disabled until the API's Retry-After has passed
  void _startWait(Duration d) {
    _timer?.cancel();
    setState(() => _wait = d.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authFlowProvider.notifier)
          .signIn(_email.text, _password.text);
    } on SignInException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.retryAfter != null) _startWait(e.retryAfter!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _busy || _wait > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.from != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Sign in to open the link you followed.'),
            ),
          TextField(
            key: const Key('email-field'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('password-field'),
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
            onSubmitted: (_) => blocked ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('auth-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('sign-in-button'),
            onPressed: blocked ? null : _submit,
            child: Text(_wait > 0 ? 'Try again in ${_wait}s' : 'Sign in'),
          ),
          const SizedBox(height: 24),
          const Text('Demo accounts (made-up data). The password is typed.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final email in personaEmails.keys)
                ActionChip(
                  label: Text(email),
                  onPressed: () => _email.text = email,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
