import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/tflite_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/confidence_gate.dart';
import 'package:plant_disease_detector/models/disease_result.dart';

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

  final List<String> _steps = const [
    "Detecting leaf boundaries...",
    "Analyzing surface texture...",
    "Matching disease patterns...",
    "Calculating confidence score...",
    "Generating diagnosis...",
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

    if (mounted) {
      ScanRecord scan;
      if (result != null) {
        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          imageUrl: widget.imagePath,
          diseaseName: result['label'] as String,
          confidenceScore: result['confidence'] as double,
          scannedAt: DateTime.now(),
          latinName: 'Unknown',
          cropType: 'Unknown',
          severity: 'none',
          fieldLocation: 'Unknown',
          treatable: false,
        );
      } else {
        // Fallback if model fails
        scan = ScanRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          imageUrl: widget.imagePath,
          diseaseName: 'Unknown',
          confidenceScore: 0.0,
          scannedAt: DateTime.now(),
          latinName: 'Unknown',
          cropType: 'Unknown',
          severity: 'none',
          fieldLocation: 'Unknown',
          treatable: false,
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagnosticResultScreen(scan: scan),
        ),
      );
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Scanned Image Preview
              _buildImagePreview(),

              const SizedBox(height: 40),

              // 2. Title
              Text(
                'Analyzing Crop...',
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
                  AppColors.primary.withOpacity(0.15),
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
                colors: [Color(0xFFF2A98A), Color(0xFFE07A5F)],
                stops: [0.0, 1.0],
                transform: GradientRotation(-3.14159 / 2),
              ).createShader(bounds),
              child: CircularProgressIndicator(
                value: _progressAnim.value,
                strokeWidth: 5,
                backgroundColor: const Color(0xFFF0EDE8),
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
                color: AppColors.primary.withOpacity(0.2),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  if (widget.imagePath.isNotEmpty)
                    Image.file(
                      File(widget.imagePath),
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.05),
                      colorBlendMode: BlendMode.darken,
                    )
                  else
                    Image.asset(
                      'assets/images/leaf_sample.png',
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.05),
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
                                AppColors.primary.withOpacity(0.9), // Bright leading edge
                                AppColors.primary.withOpacity(0.0), // Fading tail
                              ],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.8), // Core laser beam
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
              color: const Color(0xFFEDEAE5),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progressAnim.value,
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
            color: isActive ? AppColors.primary : const Color(0xFFEDEAE5),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}
