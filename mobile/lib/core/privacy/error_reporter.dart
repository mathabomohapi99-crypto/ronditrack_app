// NEW 12.1: every reported failure passes through here. Tests use the recording one, so no Sentry account is needed
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/core/privacy/scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'error_reporter.g.dart';

abstract interface class ErrorReporter {
  void report(Object error, {StackTrace? stack, String? correlationId});
}

/// Used when there is no DSN: nothing is sent, the app starts as before.
class NoopErrorReporter implements ErrorReporter {
  const new();

  @override
  void report(Object error, {StackTrace? stack, String? correlationId}) {}
}

/// Tests read what WOULD have been reported.
class RecordingErrorReporter implements ErrorReporter {
  final reports = <({Object error, String? correlationId})>[];

  @override
  void report(Object error, {StackTrace? stack, String? correlationId}) =>
      reports.add((error: error, correlationId: correlationId));
}

class SentryErrorReporter implements ErrorReporter {
  const new();

  @override
  void report(Object error, {StackTrace? stack, String? correlationId}) {
    unawaited(
      Sentry.captureEvent(
        SentryEvent(
          throwable: error,
          tags: {if (correlationId != null) correlationTag: correlationId},
        ),
        stackTrace: stack,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
ErrorReporter errorReporter(Ref ref) => const NoopErrorReporter();
