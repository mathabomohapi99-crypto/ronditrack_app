// NEW 10.3: the ONE retry rule for the app. "Not found" is never retried (a 404 will not change, and retrying shows a spinner for a minute)
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

const _maxRetries = 10;
const _baseMs = 200;
const _capMs = 6400;

Duration? appRetry(int retryCount, Object error) {
  if (error is NotFoundException) return null;
  if (retryCount >= _maxRetries) return null;
  final ms = _baseMs * (1 << retryCount);
  return Duration(milliseconds: ms > _capMs ? _capMs : ms);
}
