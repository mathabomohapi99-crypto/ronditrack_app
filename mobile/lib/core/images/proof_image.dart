// NEW 12.2: shrinks a proof photo. Turned upright, no side over maxSide, JPEG at falling quality, ALL EXIF (GPS too) cleared
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ProofTooLarge implements Exception {
  const new(this.maxBytes);

  final int maxBytes;
}

class ProofUnreadable implements Exception {
  const new();
}

const proofQualities = [85, 75, 65, 55, 45];

/// On another isolate, so the screen never freezes.
Future<Uint8List> shrinkProof(
  Uint8List bytes, {
  required int maxBytes,
  int maxSide = 1600,
}) => Isolate.run(
  () => shrinkProofSync(bytes, maxBytes: maxBytes, maxSide: maxSide),
);

Uint8List shrinkProofSync(
  Uint8List bytes, {
  required int maxBytes,
  int maxSide = 1600,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const ProofUnreadable();
  var image = img.bakeOrientation(decoded);
  if (image.width >= image.height && image.width > maxSide) {
    image = img.copyResize(image, width: maxSide);
  } else if (image.height > image.width && image.height > maxSide) {
    image = img.copyResize(image, height: maxSide);
  }
  // The image package writes back the EXIF it read, GPS included: clear it on purpose
  image.exif.clear();
  for (final q in proofQualities) {
    final out = img.encodeJpg(image, quality: q);
    if (out.length <= maxBytes) return out;
  }
  throw ProofTooLarge(maxBytes);
}
