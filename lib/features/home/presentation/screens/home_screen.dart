import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';

import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/weather/presentation/screens/weather_forecast_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Dribbble Premium Redesign
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildInitialsAvatar(String fullName, double size) {
  final parts = fullName.trim().split(' ');
  final initials = parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : (parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?');
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFE07A5F), Color(0xFFF2A98A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    final scanHistory = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Clean off-white background
      body: Stack(
        children: [
          // Background Top Emerald Shape
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2618), Color(0xFF143623)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Premium Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CropGuard: AI Disease Identification',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _buildUserAvatar(userData, 32),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Good Morning, ${userData.fullName.split(' ').first}!',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            color: Color(0xFFF2CC8F), // Copper/Sand tint for name
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Dynamic Weather Widget
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherForecastScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF2CC8F).withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Weather Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFFE07A5F).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locationState.isLoading ? 'Locating...' : (locationState.address.split(',').first.isNotEmpty ? locationState.address.split(',').first : 'Unknown'),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '10:07 AM', // Mock time as in design, or dynamic
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontFamily: 'Poppins'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  weatherState.isLoading ? '--' : '${weatherState.weather?.temperature.round() ?? 24}°C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  weatherState.isLoading ? '--' : 'Sunny',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Middle Section: Recent Activities
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Manage your farm's health.",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "RECENT ACTIVITIES",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B6C5C), letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 220,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildRecentActivityImageTile(
                          'Tomato\nEarly Blight',
                          '88% Confirmed',
                          0.88,
                          'https://images.unsplash.com/photo-1592841200221-a6898f307baa?q=80&w=600&auto=format&fit=crop',
                        ),
                        _buildRecentActivityChartTile(
                          'TOMATO\nDISEASE',
                          '88% Confirmed\nSep 15',
                          0.88,
                        ),
                        if (scanHistory.isNotEmpty)
                          _buildRecentActivityImageTile(
                            scanHistory.first.diseaseName.replaceAll(' ', '\n'),
                            scanHistory.first.dateLabel,
                            0.94,
                            scanHistory.first.imageUrl,
                          ),
                      ],
                    ),
                  ),

                  // View All
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'View All >',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFC96A4F)),
                      ),
                    ),
                  ),

                  // 4. Quick Actions & Centerpiece
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildQuickActionTile(
                          context,
                          'Expert\nInsights',
                          Icons.lightbulb_rounded, // Matches the copper bulb
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertConsultScreen())),
                        ),
                        
                        // CENTERPIECE: Scan Field Button (Squarish with rounded corners)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraCaptureScreen())),
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24), // Squarish
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF143623), Color(0xFF0F2618)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF143623).withOpacity(0.4 * _pulseAnimation.value),
                                      blurRadius: 20 * _pulseAnimation.value,
                                      spreadRadius: 4 * _pulseAnimation.value,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF81B29A).withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                                    SizedBox(height: 6),
                                    Text(
                                      'Scan\nField',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                        ),

                        _buildQuickActionTile(
                          context,
                          'Community\nHub',
                          Icons.people_alt_rounded,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen())),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Promo / Upgrade Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9EAE1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC96A4F), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Upgrade to CropGuard Pro', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                                const SizedBox(height: 2),
                                const Text('Get unlimited AI scans & expert advice.', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF7A869A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(dynamic userData, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF2CC8F), width: 1.5), // Copper border
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: userData.imagePath != null
            ? ((userData.imagePath!.startsWith('http') || kIsWeb)
                ? Image.network(userData.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitialsAvatar(userData.fullName, size))
                : Image.file(File(userData.imagePath!), fit: BoxFit.cover))
            : _buildInitialsAvatar(userData.fullName, size),
      ),
    );
  }

  Widget _buildRecentActivityImageTile(String title, String subtitle, double progress, String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2D3748), height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFFC96A4F), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC96A4F)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityChartTile(String title, String subtitle, double progress) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Green Box with Chart
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF143623), Color(0xFF0F2618)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE07A5F)), // Copper
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2D3748), height: 1.2),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF7A869A), height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        color: Colors.transparent, // expand tap area
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: const Color(0xFFC96A4F), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2D3748), height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
