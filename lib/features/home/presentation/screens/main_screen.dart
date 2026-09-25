import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/home_screen.dart';
import 'package:plant_disease_detector/features/history/presentation/screens/history_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/farm_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/profile_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';

import 'package:plant_disease_detector/core/localization/app_strings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainScreen — Handles Bottom Navigation (Glassmorphism)
// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    FarmScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The active page
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          
          // Glassmorphism Bottom Nav
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, context.tr(en: 'Home', si: 'මුල් පිටුව', ta: 'முகப்பு')),
                      _buildNavItem(1, Icons.grid_view_rounded, context.tr(en: 'Farm', si: 'ගොවිපළ', ta: 'பண்ணை')),
                      const SizedBox(width: 56), // Space for FAB
                      _buildNavItem(2, Icons.history_rounded, context.tr(en: 'History', si: 'ඉතිහාසය', ta: 'வரலாறு')),
                      _buildNavItem(3, Icons.person_rounded, context.tr(en: 'Profile', si: 'පැතිකඩ', ta: 'சுயவிவரம்')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Floating Action Button (Pulsing Emerald & Copper Centerpiece)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                  );
                },
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: AppGradients.scanButton,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.copper, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.copper.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(en: 'SCAN', si: 'ස්කෑන්', ta: 'ஸ்கேன்'),
                        style: const TextStyle(
                          color: AppColors.copperLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.copper : AppColors.navInactive,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.copper : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
