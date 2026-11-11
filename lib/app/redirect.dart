// NEW 10.2: the gate as ONE pure function (no widgets) so it can be unit tested
import 'package:ronditrack/features/stokvels/domain/enums.dart';

const signInPath = '/sign-in';

// Only an address that is inside this app may be remembered across sign-in
bool isInternalAddress(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  if (!raw.startsWith('/') || raw.startsWith('//') || raw.contains(r'\')) {
    return false;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  if (uri.path == '/') return true;
  const known = {'stokvels', 'join', 'activity', 'profile'};
  return uri.pathSegments.isNotEmpty && known.contains(uri.pathSegments.first);
}

// Returns the address to go to, or null to stay where we are
String? redirectFor({required Persona? user, required Uri uri}) {
  final onSignIn = uri.path == signInPath;
  if (user == null) {
    if (onSignIn) return null;
    final target = uri.toString();
    if (uri.path != '/' && isInternalAddress(target)) {
      return '$signInPath?from=${Uri.encodeQueryComponent(target)}';
    }
    return signInPath;
  }
  if (onSignIn) {
    final from = uri.queryParameters['from'];
    return isInternalAddress(from) ? from : '/';
  }
  return null;
}
