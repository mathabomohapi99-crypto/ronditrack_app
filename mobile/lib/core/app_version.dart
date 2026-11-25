// NEW 12.2: the version a tester can quote, read from the installed build (the name comes from the git tag, the number from the CI run)
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

String versionLabel({
  required String version,
  required String build,
  required String flavor,
}) => 'Version $version ($build) · $flavor';

class VersionLabel extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snap) {
      final info = snap.data;
      if (info == null) return const SizedBox.shrink();
      return Text(
        versionLabel(
          version: info.version,
          build: info.buildNumber,
          flavor: const String.fromEnvironment('FLAVOR'),
        ),
        key: const Key('version-label'),
      );
    },
  );
}
