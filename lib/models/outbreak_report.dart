import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

class OutbreakReport {
  final String id;
  final String diseaseName;
  final String cropType;
  final int reportCount;
  final double distanceKm;
  final String timeAgo;
  final double severity; // 0.0 - 1.0
  final Color color;
  final double latitude;
  final double longitude;

  const OutbreakReport({
    required this.id,
    required this.diseaseName,
    required this.cropType,
    required this.reportCount,
    required this.distanceKm,
    required this.timeAgo,
    required this.severity,
    required this.color,
    required this.latitude,
    required this.longitude,
  });

  /// [from] is the user's position; when given, the distance is calculated
  /// instead of using the stored distance_km.
  factory OutbreakReport.fromJson(Map<String, dynamic> json, {double? fromLat, double? fromLng}) {
    double sev = (json['severity'] ?? 0.0).toDouble();
    final lat = (json['latitude'] ?? 0.0).toDouble();
    final lng = (json['longitude'] ?? 0.0).toDouble();
    double distance = (json['distance_km'] ?? 0.0).toDouble();
    if (fromLat != null && fromLng != null && (lat != 0 || lng != 0)) {
      distance = double.parse((_haversineKm(fromLat, fromLng, lat, lng)).toStringAsFixed(1));
    }
    String timeAgo = json['time_ago'] ?? '';
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (created != null) timeAgo = _ago(created);
    Color computedColor = AppColors.outbreakLow;
    if (sev >= 0.7) computedColor = AppColors.outbreakHigh;
    else if (sev >= 0.4) computedColor = AppColors.outbreakMedium;

    return OutbreakReport(
      id: json['id']?.toString() ?? '',
      diseaseName: json['disease_name'] ?? '',
      cropType: json['crop_type'] ?? '',
      reportCount: json['report_count'] ?? 0,
      distanceKm: distance,
      timeAgo: timeAgo,
      severity: sev,
      color: computedColor,
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_name': diseaseName,
      'crop_type': cropType,
      'report_count': reportCount,
      'distance_km': distanceKm,
      'time_ago': timeAgo,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

final List<OutbreakReport> mockOutbreaks = [
  OutbreakReport(
    id: 'ob1',
    diseaseName: 'Tomato Early Blight',
    cropType: 'Tomato',
    reportCount: 14,
    distanceKm: 2.3,
    timeAgo: '2h ago',
    severity: 0.9,
    color: AppColors.outbreakHigh,
    latitude: 7.954,
    longitude: 80.75, // Around Dambulla area
  ),
  OutbreakReport(
    id: 'ob2',
    diseaseName: 'Powdery Mildew',
    cropType: 'Pepper',
    reportCount: 7,
    distanceKm: 5.8,
    timeAgo: '5h ago',
    severity: 0.6,
    color: AppColors.outbreakMedium,
    latitude: 8.01,
    longitude: 80.68,
  ),
  OutbreakReport(
    id: 'ob3',
    diseaseName: 'Root Rot',
    cropType: 'Cucumber',
    reportCount: 3,
    distanceKm: 9.1,
    timeAgo: '1d ago',
    severity: 0.4,
    color: AppColors.outbreakLow,
    latitude: 7.89,
    longitude: 80.78,
  ),
  OutbreakReport(
    id: 'ob4',
    diseaseName: 'Leaf Spot',
    cropType: 'Paddy',
    reportCount: 21,
    distanceKm: 12.4,
    timeAgo: '3h ago',
    severity: 0.75,
    color: AppColors.outbreakHigh,
    latitude: 8.05,
    longitude: 80.80,
  ),
  OutbreakReport(
    id: 'ob5',
    diseaseName: 'Anthracnose',
    cropType: 'Mango',
    reportCount: 5,
    distanceKm: 15.2,
    timeAgo: '2d ago',
    severity: 0.5,
    color: AppColors.outbreakMedium,
    latitude: 7.80,
    longitude: 80.65,
  ),
];

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}
