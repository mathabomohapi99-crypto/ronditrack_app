// NEW 12.2: a push is a nudge to fetch. This turns its data into an in-app address, or null. Known type and plain ids only
import 'package:ronditrack/app/redirect.dart';

const knownPushTypes = {
  'contribution_confirmed',
  'cycle_closed',
  'payout_recorded',
};
final _plainId = RegExp(r'^[A-Za-z0-9\-]{1,64}$');

String? routeForPush(Map<String, Object?> data) {
  final type = data['type'];
  final stokvel = data['stokvelId'];
  final cycle = data['cycleId'];
  if (type is! String || !knownPushTypes.contains(type)) return null;
  if (stokvel is! String || cycle is! String) return null;
  if (!_plainId.hasMatch(stokvel) || !_plainId.hasMatch(cycle)) return null;
  final address = '/stokvels/$stokvel/cycles/$cycle';
  return isInAppAddress(address) ? address : null;
}
