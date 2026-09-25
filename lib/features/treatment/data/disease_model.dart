import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

enum DiseaseSeverity { low, medium, high }

DiseaseSeverity _parseSeverity(String val) {
  switch (val.toLowerCase()) {
    case 'low': return DiseaseSeverity.low;
    case 'medium': return DiseaseSeverity.medium;
    case 'high': return DiseaseSeverity.high;
    default: return DiseaseSeverity.medium;
  }
}

class Disease {
  final String id;
  final String name;
  final String cropName;
  final DiseaseSeverity severity;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final String imageUrl;

  const Disease({
    required this.id,
    required this.name,
    required this.cropName,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.imageUrl,
  });

  Color get severityColor {
    switch (severity) {
      case DiseaseSeverity.low:
        return AppColors.severityDefault; // Green
      case DiseaseSeverity.medium:
        return AppColors.warning; // Orange
      case DiseaseSeverity.high:
        return AppColors.error; // Red
    }
  }

  String get severityLabel {
    switch (severity) {
      case DiseaseSeverity.low:
        return 'Low Severity';
      case DiseaseSeverity.medium:
        return 'Medium Severity';
      case DiseaseSeverity.high:
        return 'High Severity';
    }
  }
  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'] as String,
      name: json['name_en'] as String,
      cropName: json['crop'] as String,
      severity: _parseSeverity(json['severity'] ?? 'medium'),
      description: json['description'] ?? '',
      symptoms: (json['symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      causes: (json['causes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      treatments: (json['treatments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['reference_image_url'] as String? ?? 'https://images.unsplash.com/photo-1596541570197-047cf395bc24?q=80&w=800&auto=format&fit=crop',
    );
  }
}
