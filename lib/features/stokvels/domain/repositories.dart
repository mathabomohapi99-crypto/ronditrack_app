// NEW: repository interfaces; widgets only ever see these. NotFoundException = the API's 404 (also for non-members)
import 'package:ronditrack/features/stokvels/domain/models.dart';

class NotFoundException implements Exception {
  const new();
}

abstract interface class HomeRepository {
  Future<List<HomeEntry>> loadHome();
}

abstract interface class StokvelRepository {
  Future<StokvelDetail> load(String stokvelId);
}
