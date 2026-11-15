// NEW 10.2: fake activity feed across my stokvels, built from the home repository (same fakes, same persona)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/core/money/money_format.dart';

part 'activity_provider.g.dart';

@riverpod
Future<List<String>> activity(Ref ref) async {
  final entries = await ref.watch(homeRepositoryProvider).loadHome();
  return [
    for (final e in entries) ...[
      '${e.name}: you have paid ${formatRand(e.paid)} and owe ${formatRand(e.owed)}.',
      if (e.arrears.value > 0)
        '${e.name}: you are in arrears by ${formatRand(e.arrears)}.',
    ],
  ];
}
