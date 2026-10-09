import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/models/disease_result.dart';
import 'package:plant_disease_detector/core/providers/market_provider.dart';
import 'package:plant_disease_detector/models/market_price.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/main_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_detail_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/nearest_officer_screen.dart';
import 'package:plant_disease_detector/core/providers/database_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/confidence_gate.dart';
import 'package:plant_disease_detector/core/database/app_database.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/home/application/saved_items_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DiagnosticResultScreen — Matches Figma ResultsScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class DiagnosticResultScreen extends ConsumerStatefulWidget {
  final ScanRecord? scan;

  /// True only when opened straight after a scan. Results opened again from
  /// Home or History are already saved and must not be stored a second time.
  final bool isNewScan;

  const DiagnosticResultScreen({super.key, this.scan, this.isNewScan = false});

  @override
  ConsumerState<DiagnosticResultScreen> createState() => _DiagnosticResultScreenState();
}

class _DiagnosticResultScreenState extends ConsumerState<DiagnosticResultScreen>
    with SingleTickerProviderStateMixin {
  late final ScanRecord _scan;
  bool _isSymptomsTab = true;
  bool _showShareModal = false;
  bool _isSaved = false;

  late AnimationController _confCtrl;
  late Animation<double> _confAnim;

  /// Catalog entry for the detected disease (null for unknown labels).
  DiseaseInfo? get _info => DiseaseCatalog.lookup(_scan.diseaseName);

  List<String> get _symptoms => _info?.symptoms ?? const [
        'The disease could not be identified from this photo',
        'Retake the photo of a single leaf in good daylight',
        'Ask an agricultural officer to check the plant',
      ];

  List<Map<String, String>> get _treatments {
    final steps = _info?.treatments ??
        const [
          DiseaseStep('Retake the Photo', 'Photograph one affected leaf, close up, in daylight.'),
          DiseaseStep('Ask an Officer', 'Use Expert Help to send the problem to your Agriculture Instructor.'),
        ];
    return [
      for (var i = 0; i < steps.length; i++)
        {'step': (i + 1).toString().padLeft(2, '0'), 'title': steps[i].title, 'desc': steps[i].desc},
    ];
  }

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
    );
    
    _confCtrl.forward();

    if (widget.isNewScan) _saveDiagnosis();
  }

  Future<void> _saveDiagnosis() async {
    final db = ref.read(databaseProvider);
    final confidenceResult = ConfidenceGate.evaluate(_scan.confidenceScore);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      // Save locally so the result is kept even without internet.
      await db.into(db.cachedDiagnoses).insert(
        CachedDiagnosesCompanion.insert(
          id: _scan.id,
          userId: userId ?? 'local_user',
          imagePath: drift.Value(_scan.imageUrl),
          diseaseId: drift.Value(_scan.diseaseName),
          confidence: drift.Value(_scan.confidenceScore),
          clientUuid: _scan.id,
          cropHint: drift.Value(_scan.cropType),
          status: drift.Value(confidenceResult == ConfidenceResult.escalate ? 'escalated' : 'auto'),
        ),
        mode: drift.InsertMode.insertOrIgnore,
      );

      // Queue the row for the Supabase `scans` table (same columns).
      await db.into(db.outbox).insert(
        OutboxCompanion.insert(
          clientUuid: _scan.id,
          payload: jsonEncode({
            'id': _scan.id,
            'user_id': userId,
            ..._scan.toJson(),
            'symptoms': _info?.symptoms,
          }),
          type: 'diagnosis',
        ),
        mode: drift.InsertMode.insertOrIgnore,
      );

      // Upload now if online, then refresh Home / History with the new scan.
      await ref.read(outboxProcessorProvider).processOutbox();
      ref.invalidate(scanHistoryProvider);
    } catch (e) {
      debugPrint('Could not save diagnosis: $e');
    }

    if (confidenceResult == ConfidenceResult.escalate && mounted) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _showEscalateModal();
      });
    }
  }

  void _showEscalateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.tabInactiveBg,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.severityHigh.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.severityHigh, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(en: 'Could not identify this leaf', si: 'මෙම කොළය හඳුනාගත නොහැකි විය', ta: 'இந்த இலையை அடையாளம் காண முடியவில்லை'), style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(context.tr(en: 'Confidence below 40%', si: 'නිශ්චිතභාවය 40% ට අඩුයි', ta: 'நம்பகத்தன்மை 40% க்கும் குறைவு'), style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                en: 'The photo may be blurry, too dark, or not a crop leaf the app knows. Retake a close photo of one leaf in daylight, or ask an agricultural officer.',
                si: 'ඡායාරූපය බොඳ, අඳුරු හෝ යෙදුම නොදන්නා බෝග කොළයක් විය හැක. දිවා ආලෝකයේ එක් කොළයක් ළඟින් නැවත ඡායාරූප ගන්න, නැතහොත් කෘෂිකර්ම නිලධාරියෙකුගෙන් විමසන්න.',
                ta: 'புகைப்படம் மங்கலாக, இருட்டாக அல்லது பயன்பாட்டுக்குத் தெரியாத இலையாக இருக்கலாம். பகல் வெளிச்சத்தில் ஒரு இலையை அருகில் மீண்டும் படம் எடுக்கவும், அல்லது வேளாண் அலுவலரிடம் கேளுங்கள்.',
              ),
              style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _sendToOfficer();
              },
              icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
              label: Text(context.tr(en: 'Ask an Officer', si: 'නිලධාරියෙකුගෙන් විමසන්න', ta: 'அலுவலரிடம் கேளுங்கள்'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CameraCaptureScreen()));
              },
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              label: Text(context.tr(en: 'Retake Photo', si: 'නැවත ඡායාරූප ගන්න', ta: 'மீண்டும் படம் எடு'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr(en: 'View Result Anyway', si: 'ප්‍රතිඵලය බලන්න', ta: 'முடிவைப் பார்க்கவும்'), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  final FlutterTts _tts = FlutterTts();

  /// Short spoken summary of the result in the app's language.
  String _spokenSummary() {
    final pct = (_scan.confidenceScore * 100).round();
    final name = context.trDisease(_scan.diseaseName);
    final steps = _treatments.take(2).map((t) => context.trTreatment(t['title']!)).join('. ');
    if (_info?.isHealthy == true) {
      return context.tr(
        en: 'The leaf looks healthy. Confidence $pct percent. Keep checking your crop every week.',
        si: 'කොළය නිරෝගී බව පෙනේ. නිශ්චිතභාවය සියයට $pct. සෑම සතියකම ඔබේ වගාව පරීක්ෂා කරන්න.',
        ta: 'இலை ஆரோக்கியமாகத் தெரிகிறது. நம்பகத்தன்மை $pct சதவீதம். ஒவ்வொரு வாரமும் பயிரைச் சரிபார்க்கவும்.',
      );
    }
    return context.tr(
      en: 'Detected $name. Confidence $pct percent. What to do: $steps.',
      si: '$name හඳුනාගෙන ඇත. නිශ්චිතභාවය සියයට $pct. කළ යුතු දේ: $steps.',
      ta: '$name கண்டறியப்பட்டது. நம்பகத்தன்மை $pct சதவீதம். செய்ய வேண்டியவை: $steps.',
    );
  }

  String _englishSummary() {
    final pct = (_scan.confidenceScore * 100).round();
    final steps = _treatments.take(2).map((t) => t['title']).join('. ');
    return 'Detected ${_scan.diseaseName}. Confidence $pct percent. What to do: $steps.';
  }

  Future<void> _showVoiceHelp() async {
    final messenger = ScaffoldMessenger.of(context);
    final code = AppStrings.currentLocaleCode;
    final text = _spokenSummary();
    final noVoiceText = context.tr(
      en: 'This phone has no voice for this language, so it will be read in English.',
      si: 'මෙම දුරකථනයේ සිංහල හඬක් නොමැති බැවින් ඉංග්‍රීසියෙන් කියවනු ලැබේ.',
      ta: 'இந்தத் தொலைபேசியில் தமிழ் குரல் இல்லாததால் ஆங்கிலத்தில் படிக்கப்படும்.',
    );
    var spoken = text;
    try {
      final lang = switch (code) { 'si' => 'si-LK', 'ta' => 'ta-IN', _ => 'en-US' };
      final available = code == 'en' || (await _tts.isLanguageAvailable(lang)) == true;
      await _tts.setLanguage(available ? lang : 'en-US');
      await _tts.setSpeechRate(0.45);
      if (!available) {
        spoken = _englishSummary();
        messenger.showSnackBar(SnackBar(content: Text(noVoiceText)));
      }
      await _tts.speak(spoken);
    } catch (e) {
      debugPrint('Text-to-speech failed: $e');
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.tabInactiveBg, borderRadius: BorderRadius.circular(50)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.copperLight.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.volume_up_rounded, color: AppColors.copper, size: 36),
            ),
            const SizedBox(height: 16),
            Text(context.tr(en: 'Reading the result aloud', si: 'ප්‍රතිඵලය හඬින් කියවමින්', ta: 'முடிவை உரக்கப் படிக்கிறது'),
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _tts.stop();
                      await _tts.speak(spoken);
                    },
                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                    label: Text(context.tr(en: 'Play Again', si: 'නැවත අසන්න', ta: 'மீண்டும் கேள்'), style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.tr(en: 'Stop', si: 'නවත්වන්න', ta: 'நிறுத்து')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await _tts.stop();
  }

  @override
  void dispose() {
    _tts.stop();
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
                        _buildConfidenceNotice(),
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
            AppLocalizations.of(context)?.diagnosisResult ?? 'Diagnosis Result',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LanguageSelectorButton(isCompact: true),
              const SizedBox(width: 8),
              _buildSquareButton(
                icon: _isSaved ? Icons.bookmark_rounded : Icons.ios_share_rounded,
                iconColor: _isSaved ? AppColors.primary : AppColors.settingsIcon,
                bgColor: _isSaved ? AppColors.signOutBg : AppColors.surface,
                onTap: () => setState(() => _showShareModal = true),
              ),
            ],
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
  // 40–70%: the model is unsure. Below 40% the popup already offers a retake.
  Widget _buildConfidenceNotice() {
    final gate = ConfidenceGate.evaluate(_scan.confidenceScore);
    if (gate == ConfidenceResult.show) return const SizedBox.shrink();
    final low = gate == ConfidenceResult.escalate;
    final color = low ? AppColors.severityHigh : AppColors.severityMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    low
                        ? context.tr(en: 'Could not identify this leaf', si: 'මෙම කොළය හඳුනාගත නොහැකි විය', ta: 'இந்த இலையை அடையாளம் காண முடியவில்லை')
                        : context.tr(en: 'The app is not sure', si: 'යෙදුමට විශ්වාස නැත', ta: 'பயன்பாட்டுக்கு உறுதியில்லை'),
                    style: AppTextStyles.titleSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      en: 'Compare the symptoms below with your plant. Retake a clear photo of one leaf, or ask an officer before buying chemicals.',
                      si: 'පහත රෝග ලක්ෂණ ඔබේ පැලය සමඟ සසඳන්න. එක් කොළයක පැහැදිලි ඡායාරූපයක් නැවත ගන්න, නැතහොත් රසායන මිලදී ගැනීමට පෙර නිලධාරියෙකුගෙන් විමසන්න.',
                      ta: 'கீழே உள்ள அறிகுறிகளை உங்கள் செடியுடன் ஒப்பிடுங்கள். ஒரு இலையின் தெளிவான படத்தை மீண்டும் எடுக்கவும், அல்லது இரசாயனம் வாங்கும் முன் அலுவலரிடம் கேளுங்கள்.',
                    ),
                    style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: Text(context.tr(en: 'Retake', si: 'නැවත ගන්න', ta: 'மீண்டும் எடு')),
                        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CameraCaptureScreen())),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.support_agent_rounded, size: 16),
                        label: Text(context.tr(en: 'Ask an Officer', si: 'නිලධාරියෙකුගෙන් විමසන්න', ta: 'அலுவலரிடம் கேள்')),
                        onPressed: _sendToOfficer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.mintLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.overlayDark.withValues(alpha: 0.05),
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
                              colors: [AppColors.avatarGradEnd, AppColors.avatarGradStart],
                              stops: [0.0, 1.0],
                              transform: GradientRotation(-3.14159 / 2),
                            ).createShader(bounds),
                            child: AnimatedBuilder(
                              animation: _confAnim,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _confAnim.value,
                                  strokeWidth: 7,
                                  backgroundColor: AppColors.imageLoadingBg,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeCap: StrokeCap.round,
                                );
                              },
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _confAnim,
                              builder: (context, child) {
                                return Text(
                                  '${(_confAnim.value * 100).round()}%',
                                  style: AppTextStyles.headlineLarge.copyWith(letterSpacing: -1),
                                );
                              },
                            ),
                            Text(
                              context.tr(en: 'Confidence', si: 'විශ්වාසනීයත්වය', ta: 'நம்பகத்தன்மை'),
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
                              context.tr(en: 'DETECTED', si: 'හඳුනාගත් රෝගය', ta: 'கண்டறியப்பட்டது'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.settingsIcon,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.trDisease(_scan.diseaseName),
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
                          _scan.latinName == 'No pathogen detected'
                              ? context.tr(en: 'No pathogen detected', si: 'රෝග කාරක හමු නොවීය', ta: 'நோய்க்கிருமி எதுவும் இல்லை')
                              : _scan.latinName,
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
                                '● ${context.trSeverity(_scan.severityLabel)}',
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
                                  color: AppColors.severityDefault.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  context.tr(en: 'Treatable', si: 'සුව කළ හැක', ta: 'குணப்படுத்தக்கூடியது'),
                                  style: const TextStyle(
                                    color: AppColors.emeraldDeep,
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
              const Divider(color: AppColors.dividerSubtle, height: 1),
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
                          '${context.trDate(_scan.dateLabel)}, ${_scan.timeLabel}',
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
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Row(
                            children: [
                              const Icon(Icons.memory_rounded, color: AppColors.severityDefault),
                              const SizedBox(width: 8),
                              Expanded(child: Text(context.tr(en: 'How this result was made', si: 'මෙම ප්‍රතිඵලය සෑදුණු ආකාරය', ta: 'இந்த முடிவு எப்படி உருவானது'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          content: Text(
                            context.tr(
                              en: 'An AI model on your phone (MobileNetV2, trained on 70,000 leaf photos of 38 crop diseases) compared your photo with what it learned. It works without internet. It can be wrong, especially for crops it was not trained on — confirm with an officer before spraying.',
                              si: 'ඔබේ දුරකථනයේ ඇති AI ආකෘතියක් (MobileNetV2, බෝග රෝග 38 ක කොළ ඡායාරූප 70,000 කින් පුහුණු කළ) ඔබේ ඡායාරූපය සසඳා බැලීය. එය අන්තර්ජාලය නැතිව ක්‍රියා කරයි. එය වැරදි විය හැක — ඉසීමට පෙර නිලධාරියෙකුගෙන් තහවුරු කරගන්න.',
                              ta: 'உங்கள் தொலைபேசியில் உள்ள AI மாதிரி (MobileNetV2, 38 பயிர் நோய்களின் 70,000 இலைப் படங்களில் பயிற்றுவிக்கப்பட்டது) உங்கள் படத்தை ஒப்பிட்டது. இது இணையம் இல்லாமல் வேலை செய்யும். இது தவறாக இருக்கலாம் — தெளிப்பதற்கு முன் அலுவலரிடம் உறுதிப்படுத்தவும்.',
                            ),
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr(en: 'OK', si: 'හරි', ta: 'சரி'))),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.imageLoadingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 12, color: AppColors.settingsIcon),
                          const SizedBox(width: 4),
                          Text(
                            context.tr(en: 'On-device AI', si: 'දුරකථනයේ AI', ta: 'சாதன AI'),
                            style: const TextStyle(
                              color: AppColors.settingsIcon,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
          color: AppColors.tabInactiveBg,
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
                      AppLocalizations.of(context)?.symptoms ?? 'Symptoms',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isSymptomsTab ? AppColors.textPrimary : AppColors.settingsIcon,
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
                      AppLocalizations.of(context)?.treatmentPlan ?? 'Treatment Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isSymptomsTab ? AppColors.textPrimary : AppColors.settingsIcon,
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
      final symptoms = _symptoms;
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
      final treatments = _treatments;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            ...treatments.map((t) => _buildTreatmentItem(t)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TreatmentDetailScreen(diseaseName: _scan.diseaseName, cropName: _scan.cropType)));
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
                  context.tr(
                    en: 'View Detailed Treatment Plan',
                    si: 'සම්පූර්ණ ප්‍රතිකාර සැලැස්ම බලන්න',
                    ta: 'விரிவான சிகிச்சை திட்டத்தைக் காண்க',
                  ),
                  style: const TextStyle(
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
              context.trSymptom(text),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // How serious the detected disease usually is (from the disease catalog).
  // Replaces an "affected area" figure the app cannot actually measure.
  Widget _buildAreaEstimateCard() {
    final level = _info?.severity ?? _scan.severity;
    final (fraction, color, label, hint) = switch (level) {
      'high' => (1.0, AppColors.severityHigh, context.tr(en: 'High', si: 'ඉහළ', ta: 'அதிகம்'),
          context.tr(en: 'Spreads fast and can destroy the crop. Act today.', si: 'වේගයෙන් පැතිරී වගාව විනාශ කළ හැක. අදම ක්‍රියා කරන්න.', ta: 'வேகமாகப் பரவி பயிரை அழிக்கலாம். இன்றே செயல்படுங்கள்.')),
      'medium' => (0.66, AppColors.severityMedium, context.tr(en: 'Medium', si: 'මධ්‍යම', ta: 'நடுத்தரம்'),
          context.tr(en: 'Reduces yield if not treated within a week.', si: 'සතියක් තුළ ප්‍රතිකාර නොකළහොත් අස්වැන්න අඩු වේ.', ta: 'ஒரு வாரத்திற்குள் சிகிச்சை இல்லையெனில் விளைச்சல் குறையும்.')),
      'low' => (0.33, AppColors.severityLow, context.tr(en: 'Low', si: 'අඩු', ta: 'குறைவு'),
          context.tr(en: 'Usually mild. Keep watching the plants.', si: 'සාමාන්‍යයෙන් මෘදුයි. පැල නිරීක්ෂණය කරන්න.', ta: 'பொதுவாக லேசானது. செடிகளைக் கவனித்து வாருங்கள்.')),
      _ => (0.0, AppColors.severityDefault, context.tr(en: 'None', si: 'නැත', ta: 'இல்லை'),
          context.tr(en: 'No disease found on this leaf.', si: 'මෙම කොළයේ රෝගයක් හමු නොවීය.', ta: 'இந்த இலையில் நோய் இல்லை.')),
    };
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
              Text(
                context.tr(en: 'Disease Severity', si: 'රෝගයේ බරපතලකම', ta: 'நோயின் தீவிரம்'),
                style: AppTextStyles.titleSmall,
              ),
              Text(label, style: AppTextStyles.titleSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.imageLoadingBg,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(hint, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
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
                Text(context.trTreatment(data['title']!), style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(context.trTreatment(data['desc']!), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildBottomFAB() {
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
                child: Builder(
                  builder: (context) {
                    final officerLabel = context.tr(en: 'Find Nearest Officer', si: 'ළඟම නිලධාරියා සොයන්න', ta: 'அருகிலுள்ள அலுவலரைக் கண்டறி');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              officerLabel,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Wireframe 5: [ (Mic) Voice Help ] Button
          GestureDetector(
            onTap: _showVoiceHelp,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    context.tr(en: 'Voice Help', si: 'හඬ සහාය', ta: 'குரல் உதவி'),
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Climate Context Card ────────────────────────────────────────────────────
  // Today's weather where the farmer is, and what it means for spread.
  Widget _buildClimateContextCard(LocationState locationState) {
    final weather = ref.watch(weatherProvider).weather;
    final humidity = weather?.humidity;
    final rain = (weather?.daily.isNotEmpty ?? false) ? weather!.daily.first.rainChance : null;
    final risk = (humidity == null)
        ? null
        : (humidity >= 80 || (rain ?? 0) >= 60)
            ? 'high'
            : (humidity >= 65 || (rain ?? 0) >= 30)
                ? 'medium'
                : 'low';
    final riskLabel = switch (risk) {
      'high' => context.tr(en: 'HIGH', si: 'ඉහළ', ta: 'அதிகம்'),
      'medium' => context.tr(en: 'MEDIUM', si: 'මධ්‍යම', ta: 'நடுத்தரம்'),
      'low' => context.tr(en: 'LOW', si: 'අඩු', ta: 'குறைவு'),
      _ => '—',
    };
    final riskColor = switch (risk) {
      'high' => AppColors.severityHigh,
      'medium' => AppColors.severityMedium,
      _ => AppColors.severityDefault,
    };
    final advice = switch (risk) {
      'high' => context.tr(
          en: 'Humid or rainy weather today. Leaf diseases spread fastest when leaves stay wet — treat early and avoid wetting the leaves.',
          si: 'අද තෙත් හෝ වැසි සහිත කාලගුණයකි. කොළ තෙත්ව පවතින විට රෝග වේගයෙන් පැතිරේ — කලින් ප්‍රතිකාර කර කොළ තෙත් කිරීමෙන් වළකින්න.',
          ta: 'இன்று ஈரமான அல்லது மழை வானிலை. இலைகள் ஈரமாக இருக்கும்போது நோய்கள் வேகமாகப் பரவும் — முன்கூட்டியே சிகிச்சை செய்யுங்கள்.'),
      'medium' => context.tr(
          en: 'Moderate humidity. Check nearby plants for the same signs over the next few days.',
          si: 'මධ්‍යම ආර්ද්‍රතාවය. ඉදිරි දින කිහිපය තුළ අවට පැලවල එම ලක්ෂණ පරීක්ෂා කරන්න.',
          ta: 'மிதமான ஈரப்பதம். அடுத்த சில நாட்களில் அருகிலுள்ள செடிகளைச் சரிபார்க்கவும்.'),
      'low' => context.tr(
          en: 'Dry weather slows most leaf diseases. A good time to spray if needed.',
          si: 'වියළි කාලගුණය බොහෝ කොළ රෝග මන්දගාමී කරයි. අවශ්‍ය නම් ඉසීමට හොඳ කාලයකි.',
          ta: 'வறண்ட வானிலை பெரும்பாலான இலை நோய்களை மெதுவாக்கும். தேவைப்பட்டால் தெளிக்க நல்ல நேரம்.'),
      _ => context.tr(en: 'Weather for your area is not available right now.', si: 'ඔබේ ප්‍රදේශයේ කාලගුණය දැන් ලබා ගත නොහැක.', ta: 'உங்கள் பகுதியின் வானிலை இப்போது கிடைக்கவில்லை.'),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.imagePlaceholder, AppColors.darkResultBg],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.severityDefault.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
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
                  color: AppColors.severityDefault.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🌦️', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(en: 'Weather & Spread Risk', si: 'කාලගුණය සහ පැතිරීමේ අවදානම', ta: 'வானிலை & பரவல் அபாயம்'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      locationState.isLoading
                          ? context.tr(en: 'Finding your location...', si: 'ස්ථානය සොයමින්...', ta: 'இருப்பிடம் கண்டறியப்படுகிறது...')
                          : locationState.address,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
            child: Text(advice, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.5)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildClimateChip('💧', context.tr(en: 'Humidity', si: 'ආර්ද්‍රතාවය', ta: 'ஈரப்பதம்'), humidity == null ? '—' : '$humidity%'),
              const SizedBox(width: 8),
              _buildClimateChip('🌡️', context.tr(en: 'Temp', si: 'උෂ්ණත්වය', ta: 'வெப்பம்'), weather == null ? '—' : '${weather.temperature.round()}°C'),
              const SizedBox(width: 8),
              _buildClimateChip('🌧️', context.tr(en: 'Rain today', si: 'අද වැසි', ta: 'இன்று மழை'), rain == null ? '—' : '$rain%'),
              const SizedBox(width: 8),
              _buildClimateChip('⚠️', context.tr(en: 'Spread risk', si: 'පැතිරීමේ අවදානම', ta: 'பரவல் அபாயம்'), riskLabel, valueColor: riskColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClimateChip(String emoji, String label, String val, {Color valueColor = Colors.white}) {
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
            Text(val, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 11)),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ── Market Prices Card ─────────────────────────────────────────────────────
  Widget _buildMarketPricesCard() {
    final marketAsync = ref.watch(marketProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: marketAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        error: (e, st) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(context.tr(en: 'Could not load market prices', si: 'වෙළඳපොළ මිල පූරණය කළ නොහැක', ta: 'சந்தை விலைகளை ஏற்ற முடியவில்லை')))),
        data: (market) {
          if (market == null || market.prices.isEmpty) {
            return Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(context.tr(en: 'No market prices available yet.', si: 'තවම වෙළඳපොළ මිල නොමැත.', ta: 'இன்னும் சந்தை விலைகள் இல்லை.'))));
          }
          final isSample = market.lastUpdated.toLowerCase().contains('sample');
          return Column(
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
                          Text(context.tr(en: 'Market Prices', si: 'වෙළඳපොළ මිල', ta: 'சந்தை விலைகள்'), style: AppTextStyles.titleSmall),
                          Text('${market.name}${market.distanceKm > 0 ? ' · ${market.distanceKm} km' : ''} · ${market.lastUpdated}',
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isSample ? AppColors.severityMedium : AppColors.severityDefault).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(isSample ? 'SAMPLE' : 'LIVE', style: TextStyle(color: isSample ? AppColors.severityMedium : AppColors.severityDefault, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerSubtle),
              ...market.prices.map((p) => _buildPriceRow(p)),
              const SizedBox(height: 8),
            ],
          );
        },
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
                color: AppColors.severityHigh.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(context.tr(en: 'BEST', si: 'හොඳම', ta: 'சிறந்த'), style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          Text(
            'Rs. ${price.pricePerKg.toStringAsFixed(0)}/kg',
            style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (isUp ? AppColors.severityDefault : AppColors.severityHigh).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isUp ? AppColors.emeraldDeep : AppColors.primary,
                ),
                Text(
                  '${price.changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isUp ? AppColors.emeraldDeep : AppColors.primary,
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
  String _shareText() {
    final pct = (_scan.confidenceScore * 100).round();
    final steps = _treatments.map((t) => '• ${t['title']}: ${t['desc']}').join('\n');
    return 'Lumina crop scan — ${_scan.dateLabel} ${_scan.timeLabel}\n'
        'Result: ${_scan.diseaseName} ($pct% confidence)\n'
        'Crop: ${_scan.cropType} · Location: ${_scan.fieldLocation}\n\n'
        'Recommended steps:\n$steps\n\n'
        'Please confirm with an agricultural officer before spraying.';
  }

  Future<void> _shareReport() async {
    setState(() => _showShareModal = false);
    await SharePlus.instance.share(ShareParams(text: _shareText(), subject: 'Lumina scan: ${_scan.diseaseName}'));
  }

  Future<void> _saveToSavedItems() async {
    final messenger = ScaffoldMessenger.of(context);
    final savedText = context.tr(en: 'Saved to Saved Items', si: 'සුරැකි අයිතම වලට සුරැකුණා', ta: 'சேமிக்கப்பட்டவையில் சேர்க்கப்பட்டது');
    final alreadyText = context.tr(en: 'Already in Saved Items', si: 'දැනටමත් සුරැකි අයිතම තුළ ඇත', ta: 'ஏற்கனவே சேமிக்கப்பட்டுள்ளது');
    final offlineText = context.tr(
      en: 'This scan has not uploaded yet. Connect to the internet and try again.',
      si: 'මෙම ස්කෑන් එක තවම උඩුගත වී නැත. අන්තර්ජාලයට සම්බන්ධ වී නැවත උත්සාහ කරන්න.',
      ta: 'இந்த ஸ்கேன் இன்னும் பதிவேற்றப்படவில்லை. இணையத்துடன் இணைத்து மீண்டும் முயற்சிக்கவும்.',
    );
    setState(() => _showShareModal = false);
    final notifier = ref.read(savedItemsProvider.notifier);
    try {
      await ref.read(savedItemsProvider.future);
    } catch (_) {}
    if (notifier.itemForScan(_scan.id) != null) {
      if (mounted) setState(() => _isSaved = true);
      messenger.showSnackBar(SnackBar(content: Text(alreadyText)));
      return;
    }
    try {
      await notifier.saveScan(_scan);
      if (mounted) setState(() => _isSaved = true);
      messenger.showSnackBar(SnackBar(content: Text(savedText), backgroundColor: AppColors.primary));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(offlineText), backgroundColor: AppColors.severityMedium));
    }
  }

  /// Opens Expert Consult with this scan attached. The scan id and photo link
  /// are only attached once the scan has reached Supabase (the consultation
  /// table links to it); offline, the disease name and crop are still filled in.
  Future<void> _sendToOfficer() async {
    if (_showShareModal) setState(() => _showShareModal = false);
    String? scanId;
    String? imageUrl;
    try {
      await ref.read(outboxProcessorProvider).processOutbox();
      final row = await Supabase.instance.client
          .from('scans')
          .select('id, image_url')
          .eq('id', _scan.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));
      if (row != null) {
        scanId = row['id'] as String?;
        imageUrl = row['image_url'] as String?;
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpertConsultScreen(
          diseaseName: _scan.diseaseName,
          scanId: scanId,
          imageUrl: imageUrl,
          crop: _scan.cropType,
          severity: _info?.severity ?? _scan.severity,
        ),
      ),
    );
  }

  Widget _buildShareModal() {
    return GestureDetector(
      onTap: () => setState(() => _showShareModal = false),
      child: Container(
        color: AppColors.overlayDark.withValues(alpha: 0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {}, // keep taps inside the sheet from closing it
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
                          decoration: BoxDecoration(color: AppColors.tabInactiveBg, borderRadius: BorderRadius.circular(50)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(context.tr(en: 'Save & Share', si: 'සුරකින්න සහ බෙදාගන්න', ta: 'சேமி & பகிர்'),
                          style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          en: 'Send this result by WhatsApp, SMS or email, keep it in Saved Items, or ask an officer.',
                          si: 'මෙම ප්‍රතිඵලය WhatsApp, SMS හෝ ඊමේල් මගින් යවන්න, සුරකින්න, හෝ නිලධාරියෙකුගෙන් විමසන්න.',
                          ta: 'இந்த முடிவை WhatsApp, SMS அல்லது மின்னஞ்சல் மூலம் அனுப்பவும், சேமிக்கவும், அல்லது அலுவலரிடம் கேட்கவும்.',
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildShareIconBtn(context.tr(en: 'Share', si: 'බෙදාගන්න', ta: 'பகிர்'), Icons.share_rounded, _shareReport),
                          _buildShareIconBtn(
                            _isSaved ? context.tr(en: 'Saved', si: 'සුරැකුණා', ta: 'சேமிக்கப்பட்டது') : context.tr(en: 'Save', si: 'සුරකින්න', ta: 'சேமி'),
                            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            _saveToSavedItems,
                          ),
                          _buildShareIconBtn(context.tr(en: 'Ask Officer', si: 'නිලධාරියාගෙන් විමසන්න', ta: 'அலுவலரிடம் கேள்'), Icons.support_agent_rounded, _sendToOfficer),
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

  Widget _buildShareIconBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.achievementInactive,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
