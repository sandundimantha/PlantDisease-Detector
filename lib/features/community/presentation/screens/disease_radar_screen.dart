import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/models/outbreak_report.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DiseaseRadarScreen extends ConsumerStatefulWidget {
  const DiseaseRadarScreen({super.key});

  @override
  ConsumerState<DiseaseRadarScreen> createState() => _DiseaseRadarScreenState();
}

class _DiseaseRadarScreenState extends ConsumerState<DiseaseRadarScreen> with TickerProviderStateMixin {
  OutbreakReport? _selectedOutbreak;
  bool _alertDismissed = false;
  bool _reported = false;
  
  final MapController _mapController = MapController();
  
  // Local list of outbreaks to allow adding a new one
  late List<OutbreakReport> _liveOutbreaks;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _liveOutbreaks = List.from(mockOutbreaks);
    
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _reportOutbreak(LatLng location) {
    setState(() {
      _reported = true;
      _liveOutbreaks.add(
        OutbreakReport(
          id: 'ob_new',
          diseaseName: 'Unknown Disease (Pending)',
          cropType: 'My Crop',
          reportCount: 1,
          distanceKm: 0.0,
          timeAgo: 'Just now',
          severity: 0.5,
          color: AppColors.outbreakHigh, // Warning red
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
    });
    
    // Fly to new marker
    _mapController.move(location, 14.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🌿 Outbreak reported! Agri Officer notified.'),
        backgroundColor: AppColors.outbreakLow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    
    // Default to Sri Lanka center if location not available yet
    final userLocation = locationState.position != null 
        ? LatLng(locationState.position!.latitude, locationState.position!.longitude)
        : const LatLng(7.8731, 80.7718); // Dambulla, SL as fallback center

    return Scaffold(
      backgroundColor: AppColors.radarDarkBg,
      body: Stack(
        children: [
          // ── The Interactive Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: locationState.position != null ? 11.0 : 7.0, // Zoom out if fallback
              onTap: (_, __) => setState(() => _selectedOutbreak = null), // Dismiss card on map tap
            ),
            children: [
              // Standard Light Map Tiles (OpenStreetMap) with fallback
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.plantdetector.plant_disease_detector',
                fallbackUrl: 'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                tileBuilder: (context, tileWidget, tile) => tileWidget,
                errorTileCallback: (tile, error, stackTrace) {
                  // silently ignore tile errors — map background shows
                },
              ),
              
              // Disease Outbreak Markers
              MarkerLayer(
                markers: _liveOutbreaks.map((outbreak) {
                  final isSelected = _selectedOutbreak?.id == outbreak.id;
                  final baseSize = 40.0 + (outbreak.severity * 40.0);
                  
                  return Marker(
                    point: LatLng(outbreak.latitude, outbreak.longitude),
                    width: baseSize * 2,
                    height: baseSize * 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedOutbreak = isSelected ? null : outbreak);
                        _mapController.move(LatLng(outbreak.latitude, outbreak.longitude), _mapController.camera.zoom);
                      },
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          final pulse = isSelected ? _pulseAnim.value : 1.0;
                          return CustomPaint(
                            painter: _HeatZonePainter(
                              color: outbreak.color,
                              pulse: pulse,
                              severity: outbreak.severity,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // User Location Marker
              if (locationState.position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.6 * _pulseAnim.value),
                                blurRadius: 20,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.my_location_rounded, size: 24, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top Bar ───────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr(en: 'Disease Radar', si: 'රෝග රේඩාර්', ta: 'நோய் ரேடார்'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        locationState.isLoading ? context.tr(en: 'Locating...', si: 'ස්ථානය සොයමින්...', ta: 'இருப்பிடம் அறியப்படுகிறது...') : locationState.address,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.outbreakHigh.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.outbreakHigh.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text('LIVE', style: TextStyle(color: AppColors.outbreakHigh, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Alert banner (dismissable) ────────────────────────────────────
          if (!_alertDismissed && _liveOutbreaks.isNotEmpty)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => setState(() => _alertDismissed = true),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.outbreakHigh.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outbreakHigh.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.outbreakHigh.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(child: Text('⚠️', style: TextStyle(fontSize: 16))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(en: 'Outbreak Alert Nearby!', si: 'ආසන්නයේ රෝග පැතිරීමක්!', ta: 'அருகில் நோய் பரவல் எச்சரிக்கை!'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    '${context.trDisease(_liveOutbreaks.first.diseaseName)} ${_liveOutbreaks.first.distanceKm}km. ${context.tr(en: 'Take precautions.', si: 'පූර්වාරක්ෂක පියවර ගන්න.', ta: 'முன்னெச்சரிக்கை எடுக்கவும்.')}',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Map Controls (Center Map) ───────────────────────────────────────
          if (locationState.position != null)
            Positioned(
              right: 20,
              bottom: _selectedOutbreak != null ? 300 : 120,
              child: FloatingActionButton(
                heroTag: 'center_map',
                backgroundColor: AppColors.radarChipBg,
                mini: true,
                onPressed: () {
                  _mapController.move(userLocation, 12.0);
                },
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
              ),
            ),

          // ── Legend (bottom-left) ──────────────────────────────────────────
          Positioned(
            bottom: _selectedOutbreak != null ? 300 : 120,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(en: 'SEVERITY', si: 'තීව්‍රතාව', ta: 'தீவிரம்'), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      _buildLegendItem(AppColors.outbreakHigh, context.trSeverity('High')),
                      const SizedBox(height: 4),
                      _buildLegendItem(AppColors.outbreakMedium, context.trSeverity('Medium')),
                      const SizedBox(height: 4),
                      _buildLegendItem(AppColors.outbreakLow, context.trSeverity('Low')),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom: Outbreak detail sheet OR report button ────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedOutbreak != null
                  ? _buildOutbreakSheet(_selectedOutbreak!)
                  : _buildBottomBar(userLocation),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.8), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ],
    );
  }

  Widget _buildBottomBar(LatLng userLocation) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: GestureDetector(
              onTap: () {
                if (!_reported) _reportOutbreak(userLocation);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _reported
                      ? AppGradients.savedOrganic
                      : AppGradients.savedChemical,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ((_reported) ? AppColors.outbreakLow : AppColors.outbreakHigh).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_reported ? Icons.check_circle_rounded : Icons.add_alert_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _reported
                          ? context.tr(en: 'Outbreak Reported!', si: 'රෝග පැතිරීම වාර්තා විය!', ta: 'நோய் பரவல் புகாரளிக்கப்பட்டது!')
                          : context.tr(en: 'Report a Disease Outbreak', si: 'රෝග පැතිරීමක් වාර්තා කරන්න', ta: 'நோய் பரவலைப் புகாரளிக்கவும்'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutbreakSheet(OutbreakReport outbreak) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.radarDarkBg.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: outbreak.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: outbreak.color.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Icon(Icons.coronavirus_rounded, color: outbreak.color, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.trDisease(outbreak.diseaseName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${context.trCrop(outbreak.cropType)} · ${outbreak.timeAgo}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedOutbreak = null),
                    child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip('📍', '${outbreak.distanceKm} km', context.tr(en: 'Distance', si: 'දුර', ta: 'தொலைவு')),
                  const SizedBox(width: 12),
                  _buildStatChip('👥', '${outbreak.reportCount}', context.tr(en: 'Reports', si: 'වාර්තා', ta: 'அறிக்கைகள்')),
                  const SizedBox(width: 12),
                  _buildStatChip('🔥', '${(outbreak.severity * 100).round()}%', context.tr(en: 'Severity', si: 'තීව්‍රතාව', ta: 'தீவிரம்')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: outbreak.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: outbreak.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: outbreak.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${context.tr(en: 'Recommended: Apply copper-based fungicide. Inspect your', si: 'නිර්දේශය: කොපර් දිලීර නාශක යොදන්න. ඔබේ', ta: 'பரிந்துரை: காப்பர் பூஞ்சைக்கொல்லியைப் பயன்படுத்துங்கள். உங்கள்')} ${context.trCrop(outbreak.cropType)} ${context.tr(en: 'crop immediately.', si: 'වගාව වහාම පරීක්ෂා කරන්න.', ta: 'பயிரை உடனடியாக பரிசோதிக்கவும்.')}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String emoji, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Custom Heat Zone Painter for Map Markers ────────────────────────────────

class _HeatZonePainter extends CustomPainter {
  final Color color;
  final double pulse;
  final double severity;

  _HeatZonePainter({required this.color, required this.pulse, required this.severity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * pulse;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6 * severity),
          color.withValues(alpha: 0.2 * severity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // Inner core
    final corePaint = Paint()..color = color.withValues(alpha: 0.8 * severity);
    canvas.drawCircle(center, radius * 0.25, corePaint);
  }

  @override
  bool shouldRepaint(covariant _HeatZonePainter old) =>
      old.pulse != pulse || old.color != color;
}
