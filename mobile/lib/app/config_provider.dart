import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/config.dart';

part 'config_provider.g.dart';

/// The one place the running flavour is read. main.dart overrides it with the
/// real config. The fallback is prod, so a forgotten override can never switch
/// dev-only tools on.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => const AppConfig(
  flavor: Flavor.prod,
  apiBaseUrl: 'https://invalid.example',
  refreshCookieName: 'unset',
);
