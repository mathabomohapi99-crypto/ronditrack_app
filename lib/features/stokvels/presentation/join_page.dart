// NEW 10.2: invite preview for /join/:code (fake); lands here after sign-in when the link was opened signed out
import 'package:flutter/material.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({required this.code, super.key});
  final String code;

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  bool _joined = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Invitation')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You are invited to join a stokvel.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Invite code: ${widget.code}'),
            const SizedBox(height: 16),
            if (_joined)
              const Text('You have joined (demo).')
            else
              FilledButton(
                onPressed: () => setState(() => _joined = true),
                child: const Text('Join'),
              ),
          ],
        ),
      ),
    ),
  );
}
