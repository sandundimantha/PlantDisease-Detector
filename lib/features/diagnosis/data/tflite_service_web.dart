import 'package:flutter/foundation.dart';

class TfLiteService {
  Future<void> initialize() async {}

  Future<Map<String, dynamic>?> analyzeImage(String imagePath, [Uint8List? imageBytes]) async {
    return {
      'label': 'Tomato Early Blight',
      'confidence': 0.94,
      'top_3': [
        {'label': 'Tomato Early Blight', 'confidence': 0.94},
        {'label': 'Tomato Late Blight', 'confidence': 0.04},
        {'label': 'Healthy', 'confidence': 0.02},
      ],
    };
  }
}
