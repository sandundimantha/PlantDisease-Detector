import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/home_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/farm_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainScreen — Premium Pill-Shaped Bottom Navigation (Dribbble Accurate)
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
    ExpertConsultScreen(),
    CommunityFeedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // The active page
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          
          // Premium Floating Pill Bottom Nav (Solid White, Copper Active)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.document_scanner_rounded, 'Scans'),
                  _buildNavItem(2, Icons.person_search_rounded, 'Expert'),
                  _buildNavItem(3, Icons.people_alt_rounded, 'Community'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: isSelected ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9EAE1) : Colors.transparent, // Light Copper Background for active
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFC96A4F) : const Color(0xFFB0B7C3), // Copper active, Grey inactive
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC96A4F),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
