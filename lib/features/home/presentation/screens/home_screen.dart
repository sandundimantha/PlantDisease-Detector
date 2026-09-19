import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/weather/presentation/screens/weather_forecast_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_catalogue_screen.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/saved_items_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/disease_radar_screen.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Matches Figma HomeScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
// Helper: builds a colored circle with the user's initials as a profile avatar fallback
Widget _buildInitialsAvatar(String fullName, double size) {
  final parts = fullName.trim().split(' ');
  final initials = parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : (parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?');
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Color(0xFFE07A5F), Color(0xFFF2A98A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanHistory = ref.watch(scanHistoryProvider);
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    final userData = ref.watch(userProvider);
    
    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting = 'Good Evening,';
    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                        Text('${userData.fullName.split(' ').first} 👋', style: AppTextStyles.headlineMedium.copyWith(letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              locationState.isLoading ? 'Locating...' : locationState.address,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE07A5F).withValues(alpha: 0.3), width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: userData.imagePath != null
                                ? ((userData.imagePath!.startsWith('http') || kIsWeb)
                                    ? Image.network(
                                        userData.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(userData.fullName, 48),
                                      )
                                    : Image.file(File(userData.imagePath!), fit: BoxFit.cover))
                                : _buildInitialsAvatar(userData.fullName, 48),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF81B29A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Weather strip
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherForecastScreen()));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildWeatherStat('💧', weatherState.isLoading ? '--' : '${weatherState.weather?.humidity ?? 72}%', 'Humidity'),
                        _buildWeatherStat('🌡️', weatherState.isLoading ? '--' : '${weatherState.weather?.temperature.toStringAsFixed(1) ?? 28.5}°C', 'Temp'),
                        _buildWeatherStat('🌬️', weatherState.isLoading ? '--' : '${weatherState.weather?.windSpeed.toStringAsFixed(1) ?? 12.0} km/h', 'Wind'),
                      ],
                    ),
                  ),
                ),
              ),

              // Disease Radar Banner
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseRadarScreen())),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A3A2A), Color(0xFF0D2518)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF81B29A).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81B29A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.radar_rounded, color: Color(0xFF81B29A), size: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Community Disease Radar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('⚠️ 14 Blight reports within 2.3km', style: TextStyle(color: Colors.red.shade300, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A5F).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: const Color(0xFFE07A5F).withValues(alpha: 0.5)),
                        ),
                        child: const Text('LIVE', style: TextStyle(color: Color(0xFFE07A5F), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Card
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraCaptureScreen()));
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE07A5F), Color(0xFFC96A4F), Color(0xFFB85A3F)],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE07A5F).withValues(alpha: 0.4), blurRadius: 48, offset: const Offset(0, 16)),
                      BoxShadow(color: const Color(0xFFE07A5F).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Subtle background image blended with the gradient
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1592841200221-a6898f307baa?q=80&w=800&auto=format&fit=crop',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -50,
                        right: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -20,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.document_scanner_outlined, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI-Powered Detection', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Scan Crop for Diseases', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontSize: 20, letterSpacing: -0.3, height: 1.1)),
                                const SizedBox(height: 6),
                                Text('Instant results · 94% accuracy', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Stats (Grid)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            context,
                            'Disease',
                            'Catalogue',
                            Icons.menu_book_rounded,
                            AppColors.primary,
                            const Color(0xFFFFFFFF),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseCatalogueScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            context,
                            'Saved',
                            'Items',
                            Icons.bookmark_rounded,
                            AppColors.primary,
                            const Color(0xFFFFF5F2),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsScreen())),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            context,
                            'Expert',
                            'Consult',
                            Icons.support_agent_rounded,
                            AppColors.secondary,
                            const Color(0xFFFFFFFF),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertConsultScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            context,
                            'Community',
                            'Forum',
                            Icons.forum_rounded,
                            AppColors.secondary,
                            const Color(0xFFF2F9F6),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen())),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recent Scans
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Scans', style: AppTextStyles.titleSmall),
                    Text('See all →', style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFE07A5F), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              SizedBox(
                height: 156,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: scanHistory.length > 5 ? 5 : scanHistory.length,
                  itemBuilder: (context, index) {
                    final scan = scanHistory[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosticResultScreen(scan: scan)));
                      },
                      child: Container(
                        width: 116,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'scan_image_${scan.id}',
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                      child: Image.network(scan.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: scan.severityColor,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        scan.severityLabel,
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(scan.diseaseName, style: AppTextStyles.titleSmall.copyWith(fontSize: 12, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(scan.dateLabel, style: AppTextStyles.bodySmall.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String icon, String val, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(child: Text(val, style: AppTextStyles.titleSmall.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickStatCard(BuildContext context, String line1, String line2, IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(line1, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(line2, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
