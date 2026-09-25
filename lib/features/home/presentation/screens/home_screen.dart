import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/weather/presentation/screens/weather_forecast_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_catalogue_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
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
        colors: [AppColors.avatarGradStart, AppColors.avatarGradEnd],
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
    final locationState = ref.watch(locationProvider);
    final weatherState = ref.watch(weatherProvider);
    final userData = ref.watch(userProvider);
    
    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context);
    String greeting = l10n?.goodEvening ?? 'Good Evening,';
    if (hour < 12) {
      greeting = l10n?.goodMorning ?? 'Good Morning,';
    } else if (hour < 17) {
      greeting = l10n?.goodAfternoon ?? 'Good Afternoon,';
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Deep Emerald Top Hero Header
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.emeraldHeader,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Title & Profile Avatar Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(
                            en: 'CropGuard: AI Disease Identification',
                            si: 'CropGuard: AI බෝග රෝග හඳුනාගැනීම',
                            ta: 'CropGuard: AI பயிர் நோய் கண்டறிதல்',
                          ),
                          style: const TextStyle(
                            color: AppColors.emeraldMist,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.copper, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.copper.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: userData.imagePath != null
                                ? ((userData.imagePath!.startsWith('http') || kIsWeb)
                                    ? Image.network(
                                        userData.imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(userData.fullName, 44),
                                      )
                                    : Image.file(File(userData.imagePath!), fit: BoxFit.cover))
                                : _buildInitialsAvatar(userData.fullName, 44),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Greeting
                    Text(
                      '$greeting ${userData.fullName.split(' ').first}!',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Glassmorphic Weather & Location Card with Copper Accents
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherForecastScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.copper,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locationState.isLoading ? 'Locating...' : (locationState.address.split(',').first),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
                                      style: const TextStyle(
                                        color: AppColors.emeraldMist,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  weatherState.isLoading ? '--' : '${weatherState.weather?.temperature.toStringAsFixed(0) ?? 24}°C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                Text(
                                  context.tr(en: 'Sunny', si: 'හිරු එළිය', ta: 'வெயில்'),
                                  style: const TextStyle(
                                    color: AppColors.copperLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Farm Subheading & Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n != null && l10n.localeName == 'si'
                          ? "ඔබේ ගොවිපළේ සෞඛ්‍යය කළමනාකරණය කරන්න."
                          : (l10n != null && l10n.localeName == 'ta'
                              ? "உங்கள் பண்ணையின் ஆரோக்கியத்தை நிர்வகிக்கவும்."
                              : "Manage your farm's health."),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (l10n?.recentScans ?? 'Recent Scans').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseCatalogueScreen())),
                          child: Text(
                            '${l10n?.seeAll ?? 'View All'} >',
                            style: const TextStyle(
                              color: AppColors.copper,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal Glassmorphic Recent Activity Tiles with Copper Data Viz Rings
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildActivityTile(
                      cropImage: 'https://images.unsplash.com/photo-1592841200221-a6898f307baa?q=80&w=400&auto=format&fit=crop',
                      diseaseName: context.trDisease('Tomato Early Blight'),
                      confidence: context.tr(en: '88% Confirmed', si: '88% තහවුරු කළා', ta: '88% உறுதிப்படுத்தப்பட்டது'),
                      date: context.tr(en: 'Today', si: 'අද', ta: 'இன்று'),
                      score: 0.88,
                    ),
                    const SizedBox(width: 14),
                    _buildActivityTileWithRing(
                      diseaseName: context.tr(en: 'TOMATO DISEASE', si: 'තක්කාලි රෝගය', ta: 'தக்காளி நோய்'),
                      confidence: context.tr(en: '88% Confirmed', si: '88% තහවුරු කළා', ta: '88% உறுதிப்படுத்தப்பட்டது'),
                      date: 'Sep 15',
                      score: 0.88,
                      isSelected: true,
                    ),
                    const SizedBox(width: 14),
                    _buildActivityTile(
                      cropImage: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?q=80&w=400&auto=format&fit=crop',
                      diseaseName: context.tr(en: 'Monstera Disease', si: 'මොන්ස්ටෙරා රෝගය', ta: 'மான்ஸ்டெரா நோய்'),
                      confidence: context.tr(en: '88% Confirmed', si: '88% තහවුරු කළා', ta: '88% உறுதிப்படுத்தப்பட்டது'),
                      date: 'Sep 10',
                      score: 0.88,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Centerpiece Control Bar (Expert Insights | Scan Field | Community Hub)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Expert Insights
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertConsultScreen())),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.copperLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.copper, size: 22),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n != null && l10n.localeName == 'si'
                                  ? 'විශේෂඥ\nඋපදෙස්'
                                  : (l10n != null && l10n.localeName == 'ta'
                                      ? 'நிபுணர்\nஉதவி'
                                      : 'Expert\nInsights'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Centerpiece Scan Button
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraCaptureScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppGradients.scanButton,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.copper, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.crop_free_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n != null && l10n.localeName == 'si'
                                        ? 'ස්කෑන්'
                                        : (l10n != null && l10n.localeName == 'ta' ? 'ஸ்கேன்' : 'Scan'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    l10n != null && l10n.localeName == 'si'
                                        ? 'ක්ෂේත්‍රය'
                                        : (l10n != null && l10n.localeName == 'ta' ? 'பயிர்' : 'Field'),
                                    style: const TextStyle(
                                      color: AppColors.copperLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Community Hub
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen())),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.people_outline_rounded, color: AppColors.primaryLight, size: 22),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n != null && l10n.localeName == 'si'
                                  ? 'ගොවි\nප්‍රජාව'
                                  : (l10n != null && l10n.localeName == 'ta'
                                      ? 'விவசாயி\nசமூகம்'
                                      : 'Community\nHub'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Upgrade to CropGuard Pro Banner with Metallic Copper Accent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.proUpgradeBanner,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.copperLight.withOpacity(0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppGradients.copper,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                en: 'Upgrade to CropGuard Pro',
                                si: 'CropGuard Pro වෙත යාවත්කාලීන වන්න',
                                ta: 'CropGuard Pro-க்கு மேம்படுத்தவும்',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                en: 'Unlimited AI scans & priority officer support',
                                si: 'අසීමිත AI ස්කෑන් සහ කෘෂිකර්ම නිලධාරී ප්‍රමුඛ සහාය',
                                ta: 'வரம்பற்ற AI ஸ்கேன்கள் & முன்னுரிமை அதிகாரி உதவி',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.copper, size: 16),
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

  Widget _buildActivityTile({
    required String cropImage,
    required String diseaseName,
    required String confidence,
    required String date,
    required double score,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 75,
              width: double.infinity,
              child: SmartImage(src: cropImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            diseaseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            confidence,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.copper,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTileWithRing({
    required String diseaseName,
    required String confidence,
    required String date,
    required double score,
    bool isSelected = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectedTileBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.copper : AppColors.border,
          width: isSelected ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppColors.copper.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 75,
            width: double.infinity,
            child: Center(
              child: SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: score,
                        strokeWidth: 6,
                        backgroundColor: AppColors.copper.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.copper),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(score * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.copperDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            diseaseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            confidence,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.copper,
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
