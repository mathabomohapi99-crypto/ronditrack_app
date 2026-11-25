import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ronditrack/core/images/proof_image.dart';

img.Image noisy(int w, int h) {
  final r = Random(1);
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    p
      ..r = r.nextInt(256)
      ..g = r.nextInt(256)
      ..b = r.nextInt(256);
  }
  return image;
}

void main() {
  test('no side is over the chosen size and it fits the limit', () {
    final out = shrinkProofSync(
      img.encodeJpg(noisy(2400, 1200)),
      maxBytes: 2000000,
    );
    final back = img.decodeJpg(out)!;
    expect(back.width, lessThanOrEqualTo(1600));
    expect(back.height, lessThanOrEqualTo(1600));
    expect(out.length, lessThanOrEqualTo(2000000));
  });

  test('a photo that is never small enough is a clear failure', () {
    expect(
      () => shrinkProofSync(img.encodeJpg(noisy(800, 800)), maxBytes: 1000),
      throwsA(isA<ProofTooLarge>()),
    );
  });

  test('the camera tags are gone from the result', () {
    final src = noisy(400, 300);
    src.exif.imageIfd.make = 'PhoneMaker';
    final withTag = img.encodeJpg(src);
    expect(
      img.decodeJpg(withTag)!.exif.imageIfd.make,
      'PhoneMaker',
      reason: 'the test photo must carry a tag',
    );
    final out = shrinkProofSync(withTag, maxBytes: 2000000);
    expect(img.decodeJpg(out)!.exif.isEmpty, isTrue);
  });

  test('a real geotagged photo loses its location', () {
    final f = File('test/fixtures/geotagged.jpg');
    if (!f.existsSync()) {
      markTestSkipped(
        'put a phone photo with a location at test/fixtures/geotagged.jpg',
      );
      return;
    }
    final before = img.decodeJpg(f.readAsBytesSync())!;
    expect(
      before.exif.gpsIfd.isNotEmpty,
      isTrue,
      reason: 'the fixture must carry GPS',
    );
    final out = shrinkProofSync(f.readAsBytesSync(), maxBytes: 2000000);
    expect(img.decodeJpg(out)!.exif.gpsIfd.isEmpty, isTrue);
  });
}
