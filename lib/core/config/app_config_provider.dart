// NEW 10.3: the loaded config as a provider. main() fills it in; tests fill it in per flavour
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);
