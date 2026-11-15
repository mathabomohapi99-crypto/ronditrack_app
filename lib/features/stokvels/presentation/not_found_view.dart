// NEW 10.2: the ONE answer for a stokvel/cycle that is missing OR not yours (never "no access")
import 'package:flutter/material.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'We could not find that page.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
