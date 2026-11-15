// NEW 10.2: one stokvel card for Home and the Stokvels list; status by words + token colour, no typed colours
import 'package:flutter/material.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/theme/status_chip.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/features/stokvels/domain/labels.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';

String formatDate(DateTime? d) => d == null
    ? 'none yet'
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class StokvelCard extends StatelessWidget {
  const StokvelCard({
    required this.entry,
    required this.onTap,
    this.selected = false,
    super.key,
  });
  final HomeEntry entry;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Your role: ${roleLabel(entry.role)}'),
              Text('Paid ${formatRand(entry.paid)}'),
              Text('Owed ${formatRand(entry.owed)}'),
              Text('Next payout: ${formatDate(entry.nextPayout)}'),
              const SizedBox(height: 8),
              if (entry.arrears.value > 0)
                StatusChip(
                  label: 'Arrears ${formatRand(entry.arrears)}',
                  tone: context.statusColors.arrears,
                )
              else
                Text('Arrears ${formatRand(entry.arrears)}'),
            ],
          ),
        ),
      ),
    );
  }
}
