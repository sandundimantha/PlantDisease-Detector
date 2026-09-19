import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/models/disease_result.dart';
import 'package:plant_disease_detector/models/market_price.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/main_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_detail_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/nearest_officer_screen.dart';
import 'package:plant_disease_detector/models/agri_officer.dart';
import 'package:plant_disease_detector/core/providers/database_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/confidence_gate.dart';
import 'package:plant_disease_detector/core/database/app_database.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// DiagnosticResultScreen — Matches Figma ResultsScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class DiagnosticResultScreen extends ConsumerStatefulWidget {
  final ScanRecord? scan;

  const DiagnosticResultScreen({super.key, this.scan});

  @override
  ConsumerState<DiagnosticResultScreen> createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends ConsumerState<DiagnosticResultScreen>
    with SingleTickerProviderStateMixin {
  late final ScanRecord _scan;
  bool _isSymptomsTab = true;
  bool _showContactModal = false;
  bool _showShareModal = false;
  bool _isSaved = false;

  late AnimationController _confCtrl;
  late Animation<double> _confAnim;

  // Mock Data maps based on Figma
  final Map<String, List<String>> _symptomMap = {
    "Tomato Early Blight": [
      "Dark brown concentric rings on leaves",
      "Yellow halo surrounding lesions",
      "Premature leaf drop and defoliation",
      "Affects lower leaves first, spreads upward",
    ],
  };

  final Map<String, List<Map<String, String>>> _treatmentMap = {
    "Tomato Early Blight": [
      {"step": "01", "title": "Remove Affected Leaves", "desc": "Prune and destroy all visibly infected foliage immediately."},
      {"step": "02", "title": "Apply Fungicide", "desc": "Use copper-based or chlorothalonil fungicide every 7–10 days."},
      {"step": "03", "title": "Improve Air Circulation", "desc": "Space plants adequately. Avoid overhead irrigation."},
      {"step": "04", "title": "Soil Nutrition", "desc": "Boost potassium levels to strengthen plant immunity."},
    ],
  };

  @override
  void initState() {
    super.initState();
    _scan = widget.scan ?? mockScanHistory.first;

    _confCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _confAnim = Tween<double>(begin: 0, end: _scan.confidenceScore).animate(
      CurvedAnimation(parent: _confCtrl, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() {}));
    
    _confCtrl.forward();

    _saveDiagnosis();
  }

  Future<void> _saveDiagnosis() async {
    final db = ref.read(databaseProvider);
    final confidenceResult = ConfidenceGate.evaluate(_scan.confidenceScore);

    // Save locally
    await db.into(db.cachedDiagnoses).insert(
      CachedDiagnosesCompanion.insert(
        id: _scan.id.toString(),
        userId: 'local_user', // Mock user id for now
        imagePath: drift.Value(_scan.imageUrl),
        diseaseId: drift.Value(_scan.diseaseName),
        confidence: drift.Value(_scan.confidenceScore),
        clientUuid: _scan.id.toString(),
        status: drift.Value(confidenceResult == ConfidenceResult.escalate ? 'escalated' : 'auto'),
      ),
    );

    // Add to outbox for sync
    await db.into(db.outbox).insert(
      OutboxCompanion.insert(
        clientUuid: _scan.id.toString(),
        payload: jsonEncode({
          'id': _scan.id,
          'disease': _scan.diseaseName,
          'confidence': _scan.confidenceScore,
          'image': _scan.imageUrl,
        }),
        type: 'diagnosis',
      ),
    );

    // Trigger sync
    ref.read(outboxProcessorProvider).processOutbox();

    if (confidenceResult == ConfidenceResult.escalate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Low confidence score. Please consult an officer.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confCtrl.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopNav(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120), // Space for FAB
                    child: Column(
                      children: [
                        _buildHeroCard(),
                        _buildTabSelector(),
                        _buildContentList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed bottom FAB
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomFAB(),
          ),

          // Modals
          if (_showContactModal) _buildContactModal(),
          if (_showShareModal) _buildShareModal(),
        ],
      ),
    );
  }

  // ── Top Nav ────────────────────────────────────────────────────────────────
  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSquareButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _onBack,
          ),
          Text(
            'Diagnosis Result',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
          ),
          _buildSquareButton(
            icon: _isSaved ? Icons.bookmark_rounded : Icons.ios_share_rounded,
            iconColor: _isSaved ? AppColors.primary : const Color(0xFF9AA5B4),
            bgColor: _isSaved ? const Color(0xFFFFF5F2) : Colors.white,
            onTap: () => setState(() => _showShareModal = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color bgColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }

  // ── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF5F2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // BG Blob
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.1), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Progress
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 115,
                          height: 115,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const SweepGradient(
                              colors: [Color(0xFFF2A98A), Color(0xFFE07A5F)],
                              stops: [0.0, 1.0],
                              transform: GradientRotation(-3.14159 / 2),
                            ).createShader(bounds),
                            child: CircularProgressIndicator(
                              value: _confAnim.value,
                              strokeWidth: 7,
                              backgroundColor: const Color(0xFFF0EDE8),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_confAnim.value * 100).round()}%',
                              style: AppTextStyles.headlineLarge.copyWith(letterSpacing: -1),
                            ),
                            Text(
                              'Confidence',
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _scan.severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'DETECTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9AA5B4),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scan.diseaseName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 17,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _scan.latinName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _scan.severityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '● ${_scan.severityLabel} Severity',
                                style: TextStyle(
                                  color: _scan.severityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_scan.treatable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF81B29A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  'Treatable',
                                  style: TextStyle(
                                    color: Color(0xFF5A9E7C),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0x0F2D3748), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Hero(
                    tag: 'scan_image_${_scan.id}',
                    child: SmartImage(
                      src: _scan.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_scan.dateLabel}, 10:42 AM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _scan.fieldLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDE8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI v2.4',
                      style: TextStyle(
                        color: Color(0xFF9AA5B4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────────────────────
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEAE5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isSymptomsTab = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isSymptomsTab ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSymptomsTab
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isSymptomsTab ? AppColors.textPrimary : const Color(0xFF9AA5B4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isSymptomsTab = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isSymptomsTab ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !_isSymptomsTab
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Treatment Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isSymptomsTab ? AppColors.textPrimary : const Color(0xFF9AA5B4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content List ───────────────────────────────────────────────────────────
  Widget _buildContentList() {
    final locationState = ref.watch(locationProvider);
    if (_isSymptomsTab) {
      final symptoms = _symptomMap["Tomato Early Blight"] ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            ...symptoms.map((s) => _buildSymptomItem(s)),
            const SizedBox(height: 12),
            _buildAreaEstimateCard(),
            const SizedBox(height: 12),
            _buildClimateContextCard(locationState),
            const SizedBox(height: 12),
            _buildMarketPricesCard(),
          ],
        ),
      );
    } else {
      final treatments = _treatmentMap["Tomato Early Blight"] ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            ...treatments.map((t) => _buildTreatmentItem(t)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TreatmentDetailScreen()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'View Detailed Treatment Plan',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSymptomItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaEstimateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Affected Area Estimate', style: AppTextStyles.titleSmall),
              Text('~35%', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE8),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF2A98A), Color(0xFFE07A5F)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on visible leaf surface analysis',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data['step']!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title']!, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(data['desc']!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildBottomFAB() {
    final locationState = ref.watch(locationProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.0),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearestOfficerScreen()),
              ),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.38), blurRadius: 32, offset: const Offset(0, 12)),
                  ],
                ),
                child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final officer = getNearestOfficer(locationState.address);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                locationState.isLoading
                                    ? 'Call Nearest Officer'
                                    : 'Officer ${officer.name.split(' ').first} · ${officer.distanceKm}km',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        );
                        }
                      ),
                    ],
                  ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _showContactModal = true),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Climate Context Card ────────────────────────────────────────────────────
  Widget _buildClimateContextCard(LocationState locationState) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A2A), Color(0xFF0D2518)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF81B29A).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF81B29A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🧠', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Climate-Aware AI Context', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(
                      locationState.isLoading ? 'Analyzing location...' : locationState.address,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF81B29A).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFF81B29A).withValues(alpha: 0.4)),
                ),
                child: const Text('WET ZONE', style: TextStyle(color: Color(0xFF81B29A), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🔬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.5),
                      children: [
                        TextSpan(
                          text: '+12% probability boost — ',
                          style: TextStyle(color: const Color(0xFFE07A5F), fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: 'Fungal diseases are highly active in high-humidity wet zones. Your location history confirms elevated risk.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildClimateChip('💧', 'High Humidity', '78%'),
              const SizedBox(width: 8),
              _buildClimateChip('🌡️', 'Temp', '28°C'),
              const SizedBox(width: 8),
              _buildClimateChip('🌧️', 'Monsoon Risk', 'HIGH'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClimateChip(String emoji, String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── Market Prices Card ─────────────────────────────────────────────────────
  Widget _buildMarketPricesCard() {
    final market = nearestMarket;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today\'s Market Prices', style: AppTextStyles.titleSmall),
                      Text('${market.name} · ${market.distanceKm} km · ${market.lastUpdated}',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81B29A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Color(0xFF81B29A), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x0F2D3748)),
          ...market.prices.map((p) => _buildPriceRow(p)).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPriceRow(MarketPrice price) {
    final isUp = price.changePercent > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Text(price.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(price.cropName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (price.isBestPrice)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE07A5F).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text('BEST', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          Text(
            'Rs. ${price.pricePerKg.toStringAsFixed(0)}/kg',
            style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (isUp ? const Color(0xFF81B29A) : const Color(0xFFE07A5F)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isUp ? const Color(0xFF5A9E7C) : AppColors.primary,
                ),
                Text(
                  '${price.changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isUp ? const Color(0xFF5A9E7C) : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modals ─────────────────────────────────────────────────────────────────
  Widget _buildContactModal() {
    return GestureDetector(
      onTap: () => setState(() => _showContactModal = false),
      child: Container(
        color: const Color(0xFF2D3748).withValues(alpha: 0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {}, // consume tap
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEAE5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Contact Officer', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        'Your assigned agricultural officer for ${_scan.fieldLocation}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      // Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAF8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=96&h=96&fit=crop&auto=format',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rajitha Perera', style: AppTextStyles.titleSmall),
                                  Text('Senior Field Officer · Zone 4', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      ...List.generate(4, (_) => const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 14)),
                                      const Icon(Icons.star_rounded, color: Color(0xFFEDEAE5), size: 14),
                                      const SizedBox(width: 4),
                                      Text('4.8', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF81B29A).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5A9E7C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildModalActionBtn('Call Now', Icons.phone_rounded, true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModalActionBtn('Message', Icons.chat_bubble_outline_rounded, false)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildModalActionBtn('Send Report', Icons.description_outlined, false)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildModalActionBtn('Schedule Visit', Icons.calendar_today_rounded, false)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalActionBtn(String label, IconData icon, bool isPrimary) {
    return GestureDetector(
      onTap: () => setState(() => _showContactModal = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: isPrimary ? AppGradients.primary : null,
          color: isPrimary ? null : const Color(0xFFF5F3F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareModal() {
    return GestureDetector(
      onTap: () => setState(() => _showShareModal = false),
      child: Container(
        color: const Color(0xFF2D3748).withValues(alpha: 0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEAE5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Save & Share', style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShareIconBtn('Save PDF', Icons.picture_as_pdf_rounded),
                          _buildShareIconBtn('Share', Icons.share_rounded),
                          _buildShareIconBtn('WhatsApp', Icons.chat_rounded),
                          _buildShareIconBtn('Email', Icons.email_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareIconBtn(String label, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() {
        _isSaved = true;
        _showShareModal = false;
      }),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
