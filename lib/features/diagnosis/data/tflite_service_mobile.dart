import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/crop_disease_v1.tflite');
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (e) {
      print('Error initializing TFLite: $e');
    }
  }

  Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    if (_interpreter == null || _labels == null) return null;

    final image = img.decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) return null;

    final resizedImage = img.copyResize(image, width: 224, height: 224);
    
    // Normalize and prepare input tensor [1, 224, 224, 3]
    var input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    var output = List.generate(1, (i) => List.filled(_labels!.length, 0.0));

    _interpreter!.run(input, output);

    final probabilities = output[0];
    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    // Sort to get top 3
    var sortedResults = List.generate(
      probabilities.length,
      (index) => {'label': _labels![index], 'confidence': probabilities[index]},
    )..sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    return {
      'label': _labels![maxIndex],
      'confidence': maxProb,
      'top_3': sortedResults.take(3).toList(),
    };
  }
}
