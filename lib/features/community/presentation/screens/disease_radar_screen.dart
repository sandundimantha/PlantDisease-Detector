import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/models/outbreak_report.dart';
import 'package:plant_disease_detector/core/providers/outbreak_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
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
  List<OutbreakReport>? _liveOutbreaks;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    
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

  /// Asks what the farmer saw, saves it to outbreak_reports and shows it on the map.
  Future<void> _reportOutbreak(LatLng location) async {
    if (_liveOutbreaks == null) return;
    final diseases = DiseaseCatalog.all.where((d) => !d.isHealthy).toList();
    String? selected; // null = not sure
    String level = 'medium';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr(en: 'Report an outbreak', si: 'රෝග පැතිරීමක් වාර්තා කරන්න', ta: 'நோய்ப் பரவலைப் புகாரளி'),
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  en: 'Your report is shown on the radar at your current location so nearby farmers and officers can see it.',
                  si: 'ඔබේ වාර්තාව ඔබේ වත්මන් ස්ථානයේ රේඩාරයේ පෙන්වයි; අවට ගොවීන්ට සහ නිලධාරීන්ට එය දැකිය හැක.',
                  ta: 'உங்கள் புகார் உங்கள் தற்போதைய இடத்தில் ரேடாரில் காட்டப்படும்; அருகிலுள்ள விவசாயிகளும் அலுவலர்களும் பார்க்கலாம்.',
                ),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(en: 'What did you see?', si: 'ඔබ දුටුවේ කුමක්ද?', ta: 'நீங்கள் என்ன பார்த்தீர்கள்?'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(context.tr(en: 'Not sure', si: 'විශ්වාස නැත', ta: 'உறுதியில்லை'))),
                  for (final d in diseases) DropdownMenuItem<String?>(value: d.label, child: Text(context.trDisease(d.label), overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setSheet(() => selected = v),
              ),
              const SizedBox(height: 14),
              Text(context.tr(en: 'How bad is it?', si: 'කොතරම් දරුණුද?', ta: 'எவ்வளவு மோசம்?'), style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'low', label: Text(context.tr(en: 'A few plants', si: 'පැල කිහිපයක්', ta: 'சில செடிகள்'))),
                  ButtonSegment(value: 'medium', label: Text(context.tr(en: 'Spreading', si: 'පැතිරෙමින්', ta: 'பரவுகிறது'))),
                  ButtonSegment(value: 'high', label: Text(context.tr(en: 'Whole field', si: 'මුළු කුඹුර', ta: 'முழு வயல்'))),
                ],
                selected: {level},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setSheet(() => level = v.first),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
                label: Text(context.tr(en: 'Submit report', si: 'වාර්තාව යවන්න', ta: 'புகாரைச் சமர்ப்பி'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.outbreakHigh,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final info = selected == null ? null : DiseaseCatalog.lookup(selected!);
    final severity = switch (level) { 'low' => 0.3, 'high' => 0.85, _ => 0.55 };
    final messenger = ScaffoldMessenger.of(context);
    final savedText = context.tr(
      en: 'Report saved. It now shows on the radar for farmers and officers nearby.',
      si: 'වාර්තාව සුරැකිණි. අවට ගොවීන්ට සහ නිලධාරීන්ට එය දැන් රේඩාරයේ පෙනේ.',
      ta: 'புகார் சேமிக்கப்பட்டது. அருகிலுள்ளவர்களுக்கு இப்போது ரேடாரில் தெரியும்.',
    );
    final failText = context.tr(en: 'Could not send the report. Check your connection and try again.', si: 'වාර්තාව යැවිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'புகாரை அனுப்ப முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
    try {
      await OutbreakService().createOutbreak({
        'disease_name': selected ?? 'Unconfirmed disease',
        'crop_type': info?.crop ?? 'Unknown',
        'report_count': 1,
        'severity': severity,
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
    } catch (e) {
      debugPrint('Outbreak report failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failText), backgroundColor: Colors.red));
      return;
    }
    if (!mounted) return;
    setState(() {
      _reported = true;
      _liveOutbreaks!.insert(
        0,
        OutbreakReport(
          id: 'mine',
          diseaseName: selected ?? 'Unconfirmed disease',
          cropType: info?.crop ?? 'Unknown',
          reportCount: 1,
          distanceKm: 0.0,
          timeAgo: 'Just now',
          severity: severity,
          color: severity >= 0.7 ? AppColors.outbreakHigh : (severity >= 0.4 ? AppColors.outbreakMedium : AppColors.outbreakLow),
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
    });
    _mapController.move(location, 14.0);
    messenger.showSnackBar(SnackBar(
      content: Text(savedText),
      backgroundColor: AppColors.outbreakLow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    
    // Default to Sri Lanka center if location not available yet
    final userLocation = locationState.position != null 
        ? LatLng(locationState.position!.latitude, locationState.position!.longitude)
        : const LatLng(7.8731, 80.7718); // Dambulla, SL as fallback center

    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.position == null && next.position != null) {
        final loc = LatLng(next.position!.latitude, next.position!.longitude);
        _mapController.move(loc, 11.0);
      }
    });

    final outbreaksAsync = ref.watch(outbreakProvider);
    if (_liveOutbreaks == null && outbreaksAsync.value != null) {
      _liveOutbreaks = List.from(outbreaksAsync.value!);
    }

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
              onTap: (_, _) => setState(() => _selectedOutbreak = null), // Dismiss card on map tap
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
              if (_liveOutbreaks != null)
                MarkerLayer(
                  markers: _liveOutbreaks!.map((outbreak) {
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
                          builder: (_, _) {
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
                        builder: (_, _) => Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse/Accuracy circle
                            Container(
                              width: 60 * _pulseAnim.value,
                              height: 60 * _pulseAnim.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withValues(alpha: 0.25),
                              ),
                            ),
                            // White border
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            // Inner blue dot
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                          ],
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
                    const SizedBox(width: 8),
                    const LanguageSelectorButton(isDark: true, isCompact: true),
                  ],
                ),
              ),
            ),
          ),

          // ── Alert banner (dismissable) ────────────────────────────────────
          if (!_alertDismissed && _liveOutbreaks != null && _liveOutbreaks!.isNotEmpty)
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
                                    '${_diseaseLabel(context, _liveOutbreaks!.first)} ${_liveOutbreaks!.first.distanceKm}km. ${context.tr(en: 'Take precautions.', si: 'පූර්වාරක්ෂක පියවර ගන්න.', ta: 'முன்னெச்சரிக்கை எடுக்கவும்.')}',
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

          // ── My Location Button ────────────────────────────────────────────
          if (locationState.position != null)
            Positioned(
              bottom: _selectedOutbreak != null ? 150 : 120, 
              right: 20,
              child: FloatingActionButton(
                heroTag: 'my_location_btn',
                backgroundColor: AppColors.primary,
                mini: true,
                onPressed: () {
                  _mapController.move(userLocation, 14.0);
                },
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
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
                        Text(_diseaseLabel(context, outbreak), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${_cropLabel(context, outbreak)} · ${_agoLabel(context, outbreak.timeAgo)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
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
                        _advice(context, outbreak),
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

  String _diseaseLabel(BuildContext context, OutbreakReport o) => o.diseaseName == 'Unconfirmed disease'
      ? context.tr(en: 'Unconfirmed disease', si: 'තහවුරු නොකළ රෝගය', ta: 'உறுதிப்படுத்தப்படாத நோய்')
      : context.trDisease(o.diseaseName);

  String _cropLabel(BuildContext context, OutbreakReport o) => o.cropType == 'Unknown'
      ? context.tr(en: 'Crop not given', si: 'බෝගය සඳහන් නැත', ta: 'பயிர் குறிப்பிடப்படவில்லை')
      : context.trCrop(o.cropType);

  /// "Just now", "5 min ago", "3 h ago", "2 d ago" in the app language.
  String _agoLabel(BuildContext context, String ago) {
    if (ago == 'Just now') return context.tr(en: 'Just now', si: 'දැන්', ta: 'இப்போது');
    final m = RegExp(r'^(\d+)\s*(min|h|d) ago$').firstMatch(ago);
    if (m == null) return ago;
    final n = m[1];
    return switch (m[2]) {
      'min' => context.tr(en: '$n min ago', si: 'මිනි. $n කට පෙර', ta: '$n நிமி. முன்'),
      'h' => context.tr(en: '$n h ago', si: 'පැය $n කට පෙර', ta: '$n மணி முன்'),
      _ => context.tr(en: '$n d ago', si: 'දින $n කට පෙර', ta: '$n நாள் முன்'),
    };
  }

  /// First step from the disease catalog; general advice when the disease is not known.
  String _advice(BuildContext context, OutbreakReport o) {
    final step = DiseaseCatalog.lookup(o.diseaseName)?.treatments.firstOrNull;
    final label = context.tr(en: 'Recommended', si: 'නිර්දේශය', ta: 'பரிந்துரை');
    if (step != null) return '$label: ${context.trTreatment(step.title)} — ${context.trTreatment(step.desc)}';
    return '$label: ${context.tr(
      en: 'Inspect your crop today and ask your Agriculture Instructor before spraying anything.',
      si: 'අදම ඔබේ වගාව පරීක්ෂා කර කිසිවක් ඉසීමට පෙර කෘෂිකර්ම උපදේශකගෙන් විමසන්න.',
      ta: 'இன்றே உங்கள் பயிரைச் சரிபார்த்து, எதையும் தெளிப்பதற்கு முன் வேளாண் போதனாசிரியரிடம் கேளுங்கள்.',
    )}';
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
