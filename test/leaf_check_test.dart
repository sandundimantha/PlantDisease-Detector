import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plant_disease_detector/features/diagnosis/domain/leaf_check.dart';

img.Image _solid(int r, int g, int b) {
  final image = img.Image(width: 40, height: 40);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return image;
}

double _ratioOf(String path) {
  final image = img.decodeImage(File(path).readAsBytesSync())!;
  return LeafCheck.leafPixelRatio(img.copyResize(image, width: 224, height: 224));
}

void main() {
  test('green and yellow-green count as plant colour', () {
    expect(LeafCheck.leafPixelRatio(_solid(60, 140, 50)), 1.0);
    expect(LeafCheck.leafPixelRatio(_solid(170, 180, 60)), 1.0);
  });

  test('grey, white, skin and blue do not', () {
    expect(LeafCheck.leafPixelRatio(_solid(128, 128, 128)), 0.0);
    expect(LeafCheck.leafPixelRatio(_solid(250, 250, 250)), 0.0);
    expect(LeafCheck.leafPixelRatio(_solid(225, 170, 140)), 0.0);
    expect(LeafCheck.leafPixelRatio(_solid(40, 90, 200)), 0.0);
  });

  test('sample leaf photos in the app pass the check', () {
    for (final name in ['scan_tomato', 'scan_spot', 'scan_bacterial', 'scan_leaf_curl', 'scan_powdery', 'scan_healthy']) {
      final ratio = _ratioOf('assets/images/$name.jpg');
      expect(LeafCheck.looksLikeLeaf(ratio), isTrue, reason: '$name ratio $ratio');
    }
  });
}
