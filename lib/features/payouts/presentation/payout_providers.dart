// NEW 10.3: the payout order for ONE cycle. Family keyed by two strings (never a new object per build); autoDispose
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';

part 'payout_providers.g.dart';

@riverpod
Future<List<PayoutEntry>> payoutOrder(
  Ref ref,
  String stokvelId,
  String cycleId,
) {
  ref.onDispose(
    () => debugPrint('payoutOrder disposed stokvel=$stokvelId cycle=$cycleId'),
  );
  return ref
      .watch(payoutRepositoryProvider)
      .loadPayoutOrder(stokvelId: stokvelId, cycleId: cycleId);
}
