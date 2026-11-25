// NEW 12.2: the four Firebase values come from a git-ignored config/firebase.<flavour>.json (a second --dart-define-from-file)
class FirebaseValues {
  const new({
    required this.apiKey,
    required this.appId,
    required this.senderId,
    required this.projectId,
  });

  final String apiKey;
  final String appId;
  final String senderId;
  final String projectId;
}

class FirebaseConfigError implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'FirebaseConfigError: $message';
}

/// null = push is off and the app runs as before.
FirebaseValues? readFirebaseValues({
  required String apiKey,
  required String appId,
  required String senderId,
  required String projectId,
}) {
  final all = [apiKey, appId, senderId, projectId];
  if (all.every((v) => v.isEmpty)) return null;
  if (all.any((v) => v.isEmpty)) {
    throw const FirebaseConfigError(
      'Some Firebase values are set but not all four. Fix config/firebase.<flavour>.json.',
    );
  }
  return FirebaseValues(
    apiKey: apiKey,
    appId: appId,
    senderId: senderId,
    projectId: projectId,
  );
}

FirebaseValues? firebaseValuesFromEnvironment() => readFirebaseValues(
  apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
  appId: const String.fromEnvironment('FIREBASE_APP_ID'),
  senderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
);
