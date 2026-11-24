// NEW 12.1: coverage floor. Generated code and translations are left out; nothing else is
import 'dart:io';

bool _excluded(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.contains('lib/l10n/');

void main(List<String> args) {
  var found = 0;
  var hit = 0;
  var skip = false;
  for (final line in File('coverage/lcov.info').readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      skip = _excluded(line.substring(3).replaceAll(r'\', '/'));
    } else if (!skip && line.startsWith('DA:')) {
      found++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) hit++;
    }
  }
  final pct = found == 0 ? 0.0 : hit * 100 / found;
  stdout.writeln('Coverage: ${pct.toStringAsFixed(1)}% ($hit of $found lines)');
  final floorFile = File('tool/coverage_floor.txt');
  if (args.contains('--write-floor')) {
    floorFile.writeAsStringSync('${(pct - 2).floor()}\n');
    stdout.writeln('Floor written: ${floorFile.readAsStringSync().trim()}%');
    return;
  }
  final floor = double.parse(floorFile.readAsStringSync().trim());
  if (pct < floor) {
    stdout.writeln('FAILED: below the floor of $floor%');
    exit(1);
  }
  stdout.writeln('OK: at or above the floor of $floor%');
}
