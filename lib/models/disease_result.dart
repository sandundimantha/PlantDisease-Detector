import 'dart:math';
import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

/// Disease model for holding AI diagnosis result data.
class DiseaseResult {
  final String diseaseName;
  final String latinName;
  final double confidenceScore; // 0.0 – 1.0
  final String cropType;
  final List<String> symptoms;
  final List<String> treatments;
  final String severity; // 'none' | 'low' | 'medium' | 'high'
  final String fieldLocation;
  final bool treatable;
  final DateTime scannedAt;
  final String imagePath;

  const DiseaseResult({
    required this.diseaseName,
    required this.latinName,
    required this.confidenceScore,
    required this.cropType,
    required this.symptoms,
    required this.treatments,
    required this.severity,
    required this.fieldLocation,
    required this.treatable,
    required this.scannedAt,
    required this.imagePath,
  });

  /// Mock factory – returns a random disease result for demo/HCI purposes.
  /// Replace with real ML response parsing when the model is integrated.
  factory DiseaseResult.mock(String imagePath) {
    final results = _mockDataset(imagePath);
    return results[Random().nextInt(results.length)];
  }

  static List<DiseaseResult> _mockDataset(String imagePath) => [
        DiseaseResult(
          diseaseName: 'Tomato Early Blight',
          latinName: 'Alternaria solani',
          confidenceScore: 0.85,
          cropType: 'Tomato',
          severity: 'medium',
          fieldLocation: 'Field Block A · Row 12',
          treatable: true,
          scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
          imagePath: imagePath,
          symptoms: [
            'Dark brown circular spots with concentric rings on older leaves',
            'Yellow halo surrounding the lesions',
            'Premature defoliation of lower leaves',
            'Stem lesions that may cause collar rot in seedlings',
            'Reduced fruit size and yield quality',
          ],
          treatments: [
            'Remove and destroy all infected leaves immediately',
            'Apply fungicide containing chlorothalonil or mancozeb every 7–10 days',
            'Avoid overhead irrigation; water at the base of plants',
            'Rotate crops — avoid planting tomatoes in the same location for 2 years',
            'Apply copper-based sprays as a preventive measure next season',
            'Ensure proper plant spacing for adequate air circulation',
          ],
        ),
        DiseaseResult(
          diseaseName: 'Powdery Mildew',
          latinName: 'Erysiphe cichoracearum',
          confidenceScore: 0.91,
          cropType: 'Cucumber',
          severity: 'low',
          fieldLocation: 'Field Block B · Row 4',
          treatable: true,
          scannedAt: DateTime.now().subtract(const Duration(days: 1)),
          imagePath: imagePath,
          symptoms: [
            'White powdery patches on upper leaf surfaces',
            'Yellowing and curling of affected leaves',
            'Stunted plant growth in severe cases',
            'Affected leaves may dry out and fall off prematurely',
          ],
          treatments: [
            'Apply neem oil spray every 7 days as a natural fungicide',
            'Use potassium bicarbonate or baking soda solution as a foliar spray',
            'Improve air circulation by pruning dense foliage',
            'Avoid excess nitrogen fertilizers which promote soft growth',
            'Apply sulphur-based fungicide if infection is severe',
          ],
        ),
        DiseaseResult(
          diseaseName: 'Bacterial Leaf Blight',
          latinName: 'Xanthomonas oryzae',
          confidenceScore: 0.78,
          cropType: 'Rice',
          severity: 'high',
          fieldLocation: 'Field Block C · Row 2',
          treatable: true,
          scannedAt: DateTime.now().subtract(const Duration(days: 2)),
          imagePath: imagePath,
          symptoms: [
            'Water-soaked lesions along leaf margins that turn yellow then brown',
            'Leaves wilt and dry out starting from the tips',
            'Milky or opaque bacterial ooze visible in humid conditions',
            'Wilting of entire tillers in severe cases (kresek symptom)',
            'Significant reduction in grain filling and yield',
          ],
          treatments: [
            'Remove and burn heavily infected plant material immediately',
            'Apply copper-based bactericides such as copper oxychloride',
            'Drain and dry fields periodically to reduce moisture',
            'Use certified disease-free seeds for the next planting season',
            'Apply balanced fertilization — avoid excess nitrogen',
            'Plant resistant rice varieties recommended for your region',
          ],
        ),
        DiseaseResult(
          diseaseName: 'Anthracnose',
          latinName: 'Colletotrichum gloeosporioides',
          confidenceScore: 0.82,
          cropType: 'Mango',
          severity: 'medium',
          fieldLocation: 'Field Block D · Row 8',
          treatable: true,
          scannedAt: DateTime.now().subtract(const Duration(days: 3)),
          imagePath: imagePath,
          symptoms: [
            'Dark, water-soaked lesions on leaves, flowers, and fruit',
            'Brown to black sunken spots on ripening fruit',
            'Infected flowers turn brown and drop prematurely',
            'Shot-hole appearance on leaves as lesions dry and fall out',
          ],
          treatments: [
            'Prune and destroy infected branches and fruit material',
            'Apply mancozeb or copper fungicide before and during flowering',
            'Avoid wetting foliage — use drip irrigation where possible',
            'Apply post-harvest hot water treatment (52°C for 5 minutes) on fruit',
            'Ensure good canopy ventilation by regular pruning',
          ],
        ),
        DiseaseResult(
          diseaseName: 'Downy Mildew',
          latinName: 'Plasmopara viticola',
          confidenceScore: 0.74,
          cropType: 'Grape',
          severity: 'high',
          fieldLocation: 'Field Block A · Row 7',
          treatable: true,
          scannedAt: DateTime.now().subtract(const Duration(days: 4)),
          imagePath: imagePath,
          symptoms: [
            'Oil-spot-like yellow patches on upper leaf surface',
            'White cottony fungal growth on the underside of leaves',
            'Infected shoots become stunted and twisted',
            'Fruit turns brown and mummifies without ripening',
            'Severe defoliation during humid, wet weather periods',
          ],
          treatments: [
            'Apply copper-based fungicides preventively before wet seasons',
            'Use systemic fungicides such as metalaxyl during active infection',
            'Remove and destroy all fallen infected leaves and fruit',
            'Improve vineyard air circulation through proper canopy management',
            'Avoid working in the vineyard when foliage is wet',
            'Plant downy mildew resistant grape varieties where possible',
          ],
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// ScanRecord — History item (wraps scan metadata + display helpers)
// ─────────────────────────────────────────────────────────────────────────────
class ScanRecord {
  final int id;
  final String diseaseName;
  final String latinName;
  final String cropType;
  final double confidenceScore;
  final String severity; // 'none' | 'low' | 'medium' | 'high'
  final String fieldLocation;
  final bool treatable;
  final DateTime scannedAt;
  final String imageUrl;

  const ScanRecord({
    required this.id,
    required this.diseaseName,
    required this.latinName,
    required this.cropType,
    required this.confidenceScore,
    required this.severity,
    required this.fieldLocation,
    required this.treatable,
    required this.scannedAt,
    required this.imageUrl,
  });

  Color get severityColor {
    switch (severity) {
      case 'high':   return AppColors.severityHigh;
      case 'medium': return AppColors.severityMedium;
      case 'low':    return AppColors.severityLow;
      default:       return AppColors.severityDefault;
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'high':   return 'High';
      case 'medium': return 'Medium';
      case 'low':    return 'Low';
      default:       return 'Healthy';
    }
  }

  String get dateLabel {
    final now = DateTime.now();
    final diff = now.difference(scannedAt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${scannedAt.day} ${months[scannedAt.month - 1]}';
  }

  String get timeLabel {
    final h = scannedAt.hour;
    final m = scannedAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour12:$m $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared mock scan history — used by HomeScreen + HistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
final List<ScanRecord> mockScanHistory = [
  ScanRecord(
    id: 1,
    diseaseName: 'Tomato Early Blight',
    latinName: 'Alternaria solani',
    cropType: 'Tomato',
    confidenceScore: 0.88,
    severity: 'high',
    fieldLocation: 'Field Block A · Row 12',
    treatable: true,
    scannedAt: DateTime.now().subtract(const Duration(hours: 2)),
    imageUrl: 'https://images.unsplash.com/photo-1606321620984-201c81c23e69?w=400&h=400&fit=crop&auto=format',
  ),
  ScanRecord(
    id: 2,
    diseaseName: 'Leaf Curl Virus',
    latinName: 'Begomovirus spp.',
    cropType: 'Tomato',
    confidenceScore: 0.76,
    severity: 'medium',
    fieldLocation: 'Field Block B · Row 4',
    treatable: true,
    scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    imageUrl: 'https://images.unsplash.com/photo-1603442506725-80c47a1a3aaf?w=400&h=400&fit=crop&auto=format',
  ),
  ScanRecord(
    id: 3,
    diseaseName: 'Healthy Crop',
    latinName: 'No pathogen detected',
    cropType: 'Cucumber',
    confidenceScore: 0.97,
    severity: 'none',
    fieldLocation: 'Field Block C · Row 2',
    treatable: false,
    scannedAt: DateTime.now().subtract(const Duration(days: 3)),
    imageUrl: 'https://images.unsplash.com/photo-1690553563186-ea46190f1465?w=400&h=400&fit=crop&auto=format',
  ),
  ScanRecord(
    id: 4,
    diseaseName: 'Powdery Mildew',
    latinName: 'Erysiphe cichoracearum',
    cropType: 'Grape',
    confidenceScore: 0.82,
    severity: 'low',
    fieldLocation: 'Field Block A · Row 7',
    treatable: true,
    scannedAt: DateTime.now().subtract(const Duration(days: 5)),
    imageUrl: 'https://images.unsplash.com/photo-1621499420841-397ba9372883?w=400&h=400&fit=crop&auto=format',
  ),
  ScanRecord(
    id: 5,
    diseaseName: 'Bacterial Leaf Spot',
    latinName: 'Xanthomonas campestris',
    cropType: 'Bell Pepper',
    confidenceScore: 0.71,
    severity: 'medium',
    fieldLocation: 'Field Block D · Row 9',
    treatable: true,
    scannedAt: DateTime.now().subtract(const Duration(days: 7)),
    imageUrl: 'https://images.unsplash.com/photo-1674337265830-1f87b06dbc0c?w=400&h=400&fit=crop&auto=format',
  ),
  ScanRecord(
    id: 6,
    diseaseName: 'Healthy Crop',
    latinName: 'No pathogen detected',
    cropType: 'Tomato',
    confidenceScore: 0.95,
    severity: 'none',
    fieldLocation: 'Field Block B · Row 1',
    treatable: false,
    scannedAt: DateTime.now().subtract(const Duration(days: 9)),
    imageUrl: 'https://images.unsplash.com/photo-1642307321395-b72347cbe944?w=400&h=400&fit=crop&auto=format',
  ),
];
