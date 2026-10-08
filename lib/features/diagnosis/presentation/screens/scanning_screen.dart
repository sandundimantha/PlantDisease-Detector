import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/tflite_provider.dart';
import 'package:plant_disease_detector/models/disease_result.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/shared/utils/uuid.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/leaf_check.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScanningScreen — Matches Figma ScanningScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class ScanningScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const ScanningScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late AnimationController _lineCtrl;
  late Animation<double> _progressAnim;

  List<String> get _steps => [
    context.tr(en: 'Detecting leaf boundaries...', si: 'කොළයේ මායිම් හඳුනා ගනිමින්...', ta: 'இலை எல்லைகளைக் கண்டறிகிறது...'),
    context.tr(en: 'Analyzing surface texture...', si: 'මතුපිට ස්වභාවය විශ්ලේෂණය කරමින්...', ta: 'மேற்பரப்பு அமைப்பை பகுப்பாய்வு செய்கிறது...'),
    context.tr(en: 'Matching disease patterns...', si: 'රෝග රටාවන් ගලපමින්...', ta: 'நோய் வடிவங்களை ஒப்பிடுகிறது...'),
    context.tr(en: 'Calculating confidence score...', si: 'නිශ්චිතභාවය ගණනය කරමින්...', ta: 'நம்பிக்கை மதிப்பெண்ணைக் கணக்கிடுகிறது...'),
    context.tr(en: 'Generating diagnosis...', si: 'රෝග විනිශ්චය සකසමින්...', ta: 'நோயறிதலை உருவாக்குகிறது...'),
  ];

  @override
  void initState() {
    super.initState();

    // Line moving up and down
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Total progress (2.6 seconds as in Figma)
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _progressAnim = Tween<double>(begin: 0, end: 1).animate(_progressCtrl)
      ..addListener(() => setState(() {}));

    _progressCtrl.forward();

    // Start background inference while animation plays
    _runInference();
  }

  Future<void> _runInference() async {
    final tflite = ref.read(tfliteProvider);
    final result = await tflite.analyzeImage(widget.imagePath);

    // Give animation at least some time to play
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    // The model labels any photo as one of its 38 classes, so ask before
    // showing a diagnosis for a photo that does not look like a leaf.
    final leafRatio = result?['leaf_ratio'] as double?;
    if (leafRatio != null && !LeafCheck.looksLikeLeaf(leafRatio)) {
      final proceed = await _confirmNotLeaf();
      if (!mounted) return;
      if (!proceed) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CameraCaptureScreen()));
        return;
      }
    }

    if (mounted) {
      final label = result?['label'] as String?;
      final info = label == null ? null : DiseaseCatalog.lookup(label);
      final location = ref.read(locationProvider);
      final district = ref.read(userProvider).district;
      final place = !location.isLoading && location.address.isNotEmpty
          ? location.address.split(',').first.trim()
          : district;

      // The id is a UUID so the same record can be uploaded to Supabase later
      // (offline outbox) and then bookmarked or deleted from History.
      final id = uuidV4();
      final scan = ScanRecord(
        id: id,
        imageUrl: await _keepPhoto(widget.imagePath, id),
        diseaseName: label ?? 'Unknown',
        confidenceScore: (result?['confidence'] as double?) ?? 0.0,
        scannedAt: DateTime.now(),
        latinName: info?.pathogen ?? 'Unknown',
        cropType: info?.crop ?? 'Unknown',
        severity: info?.severity ?? 'medium',
        fieldLocation: place.isNotEmpty ? place : 'Unknown',
        treatable: info?.treatable ?? false,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagnosticResultScreen(scan: scan, isNewScan: true),
        ),
      );
    }
  }

  Future<bool> _confirmNotLeaf() async {
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.eco_outlined, color: AppColors.warning, size: 36),
        title: Text(context.tr(en: 'Is this a leaf?', si: 'මෙය කොළයක්ද?', ta: 'இது இலையா?')),
        content: Text(context.tr(
          en: 'We could not find a plant leaf in this photo. For a correct result, take a close, clear photo of one leaf in daylight.',
          si: 'මෙම ඡායාරූපයේ ශාක කොළයක් හමු නොවීය. නිවැරදි ප්‍රතිඵලයක් සඳහා, දිවා ආලෝකයේ එක් කොළයක ළඟින් ගත් පැහැදිලි ඡායාරූපයක් ගන්න.',
          ta: 'இந்தப் புகைப்படத்தில் செடி இலையைக் கண்டறிய முடியவில்லை. சரியான முடிவுக்கு, பகல் வெளிச்சத்தில் ஒரு இலையை அருகில் தெளிவாகப் படம் எடுக்கவும்.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr(en: 'Continue anyway', si: 'කෙසේ වෙතත් ඉදිරියට', ta: 'இருந்தாலும் தொடரவும்')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.tr(en: 'Retake photo', si: 'නැවත ඡායාරූපය ගන්න', ta: 'மீண்டும் படம் எடு'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  /// Gallery and camera photos live in temporary cache folders that Android
  /// may clear. Copy the photo into the app's own folder so it is still there
  /// when the scan uploads (possibly much later, after being offline).
  Future<String> _keepPhoto(String path, String id) async {
    if (kIsWeb || path.isEmpty) return path;
    try {
      final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'scans'));
      await dir.create(recursive: true);
      final copy = await File(path).copy(p.join(dir.path, '$id.jpg'));
      return copy.path;
    } catch (e) {
      debugPrint('Could not keep scan photo: $e');
      return path;
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  int get _stepIndex {
    final idx = (_progressAnim.value * _steps.length).floor();
    return idx >= _steps.length ? _steps.length - 1 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8, right: 16),
                child: LanguageSelectorButton(isCompact: true),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Scanned Image Preview
                  _buildImagePreview(),

              const SizedBox(height: 40),

              // 2. Title
              Text(
                context.tr(en: 'Analyzing Crop...', si: 'වගාව පරීක්ෂා කරමින්...', ta: 'பயிரை பகுப்பாய்வு செய்கிறது...'),
                style: AppTextStyles.headlineMedium.copyWith(
                  letterSpacing: -0.4,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 8),

              // 3. Step Label
              SizedBox(
                height: 24,
                child: Text(
                  _steps[_stepIndex],
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // 4. Progress Bar
              _buildProgressBar(),

              const SizedBox(height: 24),

              // 5. Steps Dots
              _buildStepsDots(),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildImagePreview() {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0, 0.7],
              ),
            ),
          ),

          // Circular Progress Ring
          SizedBox(
            width: 148,
            height: 148,
            child: ShaderMask(
              shaderCallback: (bounds) => const SweepGradient(
                colors: [AppColors.avatarGradEnd, AppColors.avatarGradStart],
                stops: [0.0, 1.0],
                transform: GradientRotation(-3.14159 / 2),
              ).createShader(bounds),
              child: CircularProgressIndicator(
                value: _progressAnim.value,
                strokeWidth: 5,
                backgroundColor: AppColors.imageLoadingBg,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),

          // Leaf Image
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  if (widget.imagePath.isNotEmpty)
                    (kIsWeb || widget.imagePath.startsWith('http') || widget.imagePath.startsWith('blob:'))
                        ? Image.network(
                            widget.imagePath,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.05),
                            colorBlendMode: BlendMode.darken,
                          )
                        : Image.file(
                            File(widget.imagePath),
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.05),
                            colorBlendMode: BlendMode.darken,
                          )
                  else
                    Image.asset(
                      'assets/images/leaf_sample.png',
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.05),
                      colorBlendMode: BlendMode.darken,
                    ),
                  // Animated Radar Scan Sweep
                  AnimatedBuilder(
                    animation: _lineCtrl,
                    builder: (context, child) {
                      return Positioned(
                        top: _lineCtrl.value * 128 - 32, // Offset by height of the trail
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 32, // Thicker trail for "radar" effect
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.9), // Bright leading edge
                                AppColors.primary.withValues(alpha: 0.0), // Fading tail
                              ],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 2,
                              color: Colors.white.withValues(alpha: 0.8), // Core laser beam
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 224,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_progressAnim.value * 100).round()}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.tabInactiveBg,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progressAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [AppColors.avatarGradEnd, AppColors.avatarGradStart],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length, (i) {
        final isActive = i <= _stepIndex;
        final isCurrent = i == _stepIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.tabInactiveBg,
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}
