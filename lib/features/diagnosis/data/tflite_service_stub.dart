class TfLiteService {
  Future<void> initialize() async {
    // Stub for Web
    print('TFLite initialization skipped on Web');
  }

  Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    // Stub for Web - returns dummy prediction
    return {
      'label': 'Web Stub (Healthy)',
      'confidence': 0.99,
      'top_3': [
        {'label': 'Web Stub (Healthy)', 'confidence': 0.99},
        {'label': 'Web Stub (Disease 1)', 'confidence': 0.01},
      ],
    };
  }
}
