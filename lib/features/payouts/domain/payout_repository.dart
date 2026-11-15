// NEW 10.3: what the screen may ask for. A cycle this person cannot see throws NotFoundException (the API's 404)
import 'package:ronditrack/features/payouts/domain/payout_models.dart';

abstract interface class PayoutRepository {
  // The order EXACTLY as the server sends it
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  });
}
