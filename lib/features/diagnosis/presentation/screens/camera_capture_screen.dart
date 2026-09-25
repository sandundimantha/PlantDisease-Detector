import 'dart:ui';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/scanning_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/photo_guide_screen.dart';
import 'package:plant_disease_detector/core/providers/camera_provider.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> with TickerProviderStateMixin {
  int _selectedMode = 0;
  final List<String> _modes = ['Leaf Spot', 'Pest', 'Soil'];
  
  late AnimationController _scanController;
  late AnimationController _boxController;
  
  final Random _random = Random();
  final List<Rect> _aiBoxes = [];
  bool _flashOn = false;
  int _flashModeIndex = 0; // 0: Auto, 1: On, 2: Off
  static const List<String> _flashLabels = ['Auto', 'On', 'Off'];
  static const List<IconData> _flashIcons = [
    Icons.flash_auto_rounded,
    Icons.flash_on_rounded,
    Icons.flash_off_rounded,
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize Camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initializeCamera();
    });

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _boxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _generateRandomBoxes();
    _boxController.addListener(() {
      if (_boxController.value > 0.9 && _random.nextDouble() > 0.8) {
        _generateRandomBoxes();
      }
    });
  }
  
  void _generateRandomBoxes() {
    _aiBoxes.clear();
    int count = _random.nextInt(3) + 1;
    for (int i = 0; i < count; i++) {
      double x = _random.nextDouble() * 200 - 100;
      double y = _random.nextDouble() * 200 - 100;
      double size = _random.nextDouble() * 50 + 30;
      _aiBoxes.add(Rect.fromCenter(center: Offset(x, y), width: size, height: size));
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _boxController.dispose();
    // Intentionally not disposing the camera provider here to allow fast re-opening,
    // but in a real massive app, you'd call ref.read(cameraProvider.notifier).disposeCamera() 
    super.dispose();
  }

  void _onCapture() async {
    HapticFeedback.heavyImpact();
    
    final cameraState = ref.read(cameraProvider);
    if (cameraState.isInitialized && cameraState.controller != null) {
      try {
        // Flash animation effect
        setState(() => _flashOn = true);
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() => _flashOn = false);
        
        final XFile imageFile = await cameraState.controller!.takePicture();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanningScreen(imagePath: imageFile.path),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error taking picture: $e');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ScanningScreen(imagePath: ''),
            ),
          );
        }
      }
    } else {
      // Mock / Emulator fallback
      setState(() => _flashOn = true);
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _flashOn = false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ScanningScreen(imagePath: ''),
          ),
        );
      }
    }
  }

  Future<void> _onGallery() async {
    HapticFeedback.lightImpact();
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ScanningScreen(imagePath: image.path)),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _toggleFlash() {
    HapticFeedback.selectionClick();
    setState(() {
      _flashModeIndex = (_flashModeIndex + 1) % _flashLabels.length;
    });
    final controller = ref.read(cameraProvider).controller;
    if (controller != null) {
      FlashMode mode = FlashMode.auto;
      if (_flashModeIndex == 1) mode = FlashMode.always;
      if (_flashModeIndex == 2) mode = FlashMode.off;
      controller.setFlashMode(mode).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Live Feed Background
          Positioned.fill(
            child: cameraState.isInitialized && cameraState.controller != null
                ? CameraPreview(cameraState.controller!)
                : _buildMockOrLoadingFeed(cameraState),
          ),
          
          // Flash effect
          if (_flashOn)
            Positioned.fill(
              child: Container(color: Colors.white),
            ),

          // Scanning Reticle with Animation & AI Boxes
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Instruction Pill & Lighting Status (Wireframe 3)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.center_focus_strong_rounded, color: AppColors.copperLight, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            context.tr(
                              en: 'Center 1 leaf in frame',
                              si: 'එක් කොළයක් මැදට ගන්න',
                              ta: '1 இலையை நடுவில் வைக்கவும்',
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.severityDefault.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.severityDefault, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr(
                                    en: 'Good Light',
                                    si: 'හොඳ ආලෝකය',
                                    ta: 'நல்ல வெளிச்சம்',
                                  ),
                                  style: const TextStyle(color: AppColors.severityDefault, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Animated Scanner Box
                SizedBox(
                  width: 260,
                  height: 260,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_scanController, _boxController]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ModernReticlePainter(
                          scanProgress: _scanController.value,
                          boxOpacity: _boxController.value,
                          aiBoxes: _aiBoxes,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Top Bar (Glassmorphic)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopGlassButton(
                      icon: Icons.close_rounded, 
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    // Usability UI-01: Clear text label for flash button
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_flashIcons[_flashModeIndex], color: AppColors.starActive, size: 18),
                                const SizedBox(width: 6),
                                Builder(
                                  builder: (context) {
                                    final flashModeName = switch (_flashModeIndex) {
                                      0 => context.tr(en: 'Auto', si: 'ස්වයංක්‍රීය', ta: 'தானியங்கி'),
                                      1 => context.tr(en: 'On', si: 'ක්‍රියාත්මක', ta: 'இயக்கு'),
                                      2 => context.tr(en: 'Off', si: 'අක්‍රිය', ta: 'அணை'),
                                      _ => _flashLabels[_flashModeIndex],
                                    };
                                    return Text(
                                      '${context.tr(en: 'Flash: ', si: 'ෆ්ලෑෂ්: ', ta: 'ஃபிளாஷ்: ')}$flashModeName',
                                      style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Wireframe 3: [ GUIDE ? ] button triggering PhotoGuideScreen
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhotoGuideScreen()),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.copper.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.help_outline_rounded, color: AppColors.copperLight, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr(en: 'GUIDE ?', si: 'මඟපෙන්වීම ?', ta: 'வழிகாட்டி ?'),
                                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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

          // Bottom Control Panel (Premium Glassmorphism)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5)),
                  ),
                  padding: const EdgeInsets.only(top: 24, bottom: 48, left: 24, right: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Segmented Mode Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_modes.length, (index) {
                            final isSelected = _selectedMode == index;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMode = index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : [],
                                ),
                                child: Text(
                                  switch (index) {
                                    0 => context.tr(en: 'Leaf Spot', si: 'පත්‍ර ලප', ta: 'இலைப்புள்ளி'),
                                    1 => context.tr(en: 'Pest', si: 'පළිබෝධ', ta: 'பூச்சி'),
                                    2 => context.tr(en: 'Soil', si: 'පස', ta: 'மண்'),
                                    _ => _modes[index],
                                  },
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Bottom Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gallery Button
                          GestureDetector(
                            onTap: _onGallery,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(en: 'Gallery', si: 'ගැලරිය', ta: 'கேலரி'),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          // Glowing Shutter Button
                          GestureDetector(
                            onTap: _onCapture,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 3),
                                boxShadow: [
                                  BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),

                          // Advice Button
                          GestureDetector(
                            onTap: () => HapticFeedback.selectionClick(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(en: 'Advice', si: 'උපදෙස්', ta: 'ஆலோசனை'),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMockOrLoadingFeed(CameraState state) {
    if (state.errorMessage != null) {
      // Fallback if camera fails
      return Image.network(
        'https://images.unsplash.com/photo-1508175688576-0c076b47b5b5?w=800&h=1200&fit=crop&auto=format',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade900,
          child: const Center(child: Icon(Icons.camera_alt, color: Colors.white24, size: 100)),
        ),
      );
    }
    
    // Loading indicator while camera initializes
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }
}

class _ModernReticlePainter extends CustomPainter {
  final double scanProgress;
  final double boxOpacity;
  final List<Rect> aiBoxes;
  
  _ModernReticlePainter({
    required this.scanProgress, 
    required this.boxOpacity,
    required this.aiBoxes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Draw Simulated AI Bounding Boxes
    final boxPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: boxOpacity * 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    final fillPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: boxOpacity * 0.1)
      ..style = PaintingStyle.fill;
      
    for (var rect in aiBoxes) {
      canvas.drawRect(rect, boxPaint);
      canvas.drawRect(rect, fillPaint);
      // Small target cross inside the box
      canvas.drawLine(Offset(rect.center.dx - 4, rect.center.dy), Offset(rect.center.dx + 4, rect.center.dy), boxPaint);
      canvas.drawLine(Offset(rect.center.dx, rect.center.dy - 4), Offset(rect.center.dx, rect.center.dy + 4), boxPaint);
    }
    
    canvas.restore();

    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    
    // Draw 4 corners (modern scanner look)
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), framePaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), framePaint);
    
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), framePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), framePaint);
    
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), framePaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), framePaint);
    
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), framePaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), framePaint);

    // Draw animated scanning line
    final lineY = size.height * scanProgress;
    
    final linePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), linePaint);
    
    // Glowing gradient effect above the line
    final glowRect = Rect.fromLTRB(0, lineY - 40, size.width, lineY);
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.secondary.withValues(alpha: 0.0),
          AppColors.secondary.withValues(alpha: 0.3),
        ],
      ).createShader(glowRect);
      
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernReticlePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.boxOpacity != boxOpacity;
  }
}
