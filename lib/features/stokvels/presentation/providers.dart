// NEW: Home notifier + family keyed by stokvel id (autoDispose = codegen default; disposal logged by id only)
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';

part 'providers.g.dart';

@riverpod
class Home extends _$Home {
  @override
  Future<List<HomeEntry>> build() =>
      ref.watch(homeRepositoryProvider).loadHome();

  // Pull to refresh: old cards stay on screen while it reloads
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.catchError((_) => <HomeEntry>[]);
  }
}

@riverpod
Future<StokvelDetail> stokvelDetail(Ref ref, String stokvelId) {
  ref.onDispose(() => debugPrint('stokvelDetail disposed id=$stokvelId'));
  return ref.watch(stokvelRepositoryProvider).load(stokvelId);
}
