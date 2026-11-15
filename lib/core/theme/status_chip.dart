// NEW 10.2: a chip that ALWAYS says the status in words; colour only helps
import 'package:flutter/material.dart';
import 'package:ronditrack/core/theme/status_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tone.foreground),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: tone.foreground),
      ),
    ),
  );
}
