const signInPath = '/sign-in';
const splashPath = '/splash';

const _knownRoots = {'stokvels', 'activity', 'profile', 'join'};

/// True only for an address inside this app. Anything else is never
/// remembered across sign-in.
bool isInAppAddress(String? address) {
  if (address == null || address.isEmpty) return false;
  if (!address.startsWith('/') || address.startsWith('//')) return false;
  final uri = Uri.tryParse(address);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  final segments = uri.pathSegments;
  if (segments.isEmpty) return true;
  return _knownRoots.contains(segments.first);
}

String _gate(String gate, String? wanted) {
  if (wanted == null || wanted == '/' || !isInAppAddress(wanted)) return gate;
  return Uri(path: gate, queryParameters: {'from': wanted}).toString();
}

/// One function decides every navigation. UPDATED 11.2: while the stored session is
/// being restored, every address goes to the splash and remembers where it was going.
String? redirectFor({
  required bool signedIn,
  required Uri location,
  bool restoring = false,
}) {
  final onSignIn = location.path == signInPath;
  final onSplash = location.path == splashPath;
  if (restoring) {
    return onSplash ? null : _gate(splashPath, location.toString());
  }
  final from = location.queryParameters['from'];
  if (onSplash) {
    // restore finished: signed in goes on to where they were going, else to sign-in
    return signedIn
        ? (isInAppAddress(from) ? from : '/')
        : _gate(signInPath, from);
  }
  if (!signedIn) {
    return onSignIn ? null : _gate(signInPath, location.toString());
  }
  if (onSignIn) return isInAppAddress(from) ? from : '/';
  return null;
}
