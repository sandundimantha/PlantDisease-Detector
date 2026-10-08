import 'package:image/image.dart' as img;

/// Rough check that a photo shows a plant before trusting the model.
///
/// The model always picks one of its 38 classes, even for a photo of a wall
/// or a face, often with high confidence. Counting plant-coloured pixels
/// (yellow through green, with some saturation) catches most of those photos.
/// Brown or yellow diseased leaves still have enough of these pixels to pass.
class LeafCheck {
  /// Below this share of plant-coloured pixels the photo is probably not a leaf.
  static const double minLeafRatio = 0.06; // ~1% false alarms on the PlantVillage validation set

  /// Share (0–1) of pixels in [image] whose colour looks like plant tissue.
  /// Samples every [step]th pixel; a 224×224 image needs no more.
  static double leafPixelRatio(img.Image image, {int step = 2}) {
    var plant = 0;
    var total = 0;
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final p = image.getPixel(x, y);
        total++;
        if (_isPlantColour(p.r / p.maxChannelValue, p.g / p.maxChannelValue, p.b / p.maxChannelValue)) plant++;
      }
    }
    return total == 0 ? 0 : plant / total;
  }

  static bool looksLikeLeaf(double ratio) => ratio >= minLeafRatio;

  static bool _isPlantColour(num r, num g, num b) {
    final maxC = [r, g, b].reduce((a, c) => a > c ? a : c).toDouble();
    final minC = [r, g, b].reduce((a, c) => a < c ? a : c).toDouble();
    final delta = maxC - minC;
    if (maxC < 0.12) return false; // too dark to tell
    final saturation = maxC == 0 ? 0.0 : delta / maxC;
    if (saturation < 0.18 || delta == 0) return false; // grey, white, black
    double hue;
    if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
    if (hue < 0) hue += 360;
    // yellow-brown (~35°) through green to teal (~165°)
    return hue >= 35 && hue <= 165;
  }
}
