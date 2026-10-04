import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/settings_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/language_selection_screen.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/auth/user_role.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Matches Figma ProfileScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsOn = true;
  bool _locationOn = true;
  bool _offlineOn = false;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final currentLocale = ref.watch(localeProvider);

    String languageLabel = 'English';
    if (currentLocale.languageCode == 'si') {
      languageLabel = 'සිංහල (Sinhala)';
    } else if (currentLocale.languageCode == 'ta') {
      languageLabel = 'தமிழ் (Tamil)';
    }

    final scanHistory = ref.watch(scanHistoryProvider);
    final scanCount = scanHistory.maybeWhen(data: (scans) => scans.length, orElse: () => 0);

    final achievements = [
      _Achievement(icon: "🌱", label: context.tr(en: "First Scan", si: "පළමු ස්කෑන්", ta: "முதல் ஸ்கேன்"), earned: scanCount >= 1),
      _Achievement(icon: "🌿", label: context.tr(en: "10 Scans", si: "ස්කෑන් 10", ta: "10 ஸ்கேன்கள்"), earned: scanCount >= 10),
      _Achievement(icon: "🌾", label: context.tr(en: "50 Scans", si: "ස්කෑන් 50", ta: "50 ஸ்கேன்கள்"), earned: scanCount >= 50),
      _Achievement(icon: "🏆", label: context.tr(en: "100 Scans", si: "ස්කෑන් 100", ta: "100 ஸ்கேன்கள்"), earned: scanCount >= 100),
      _Achievement(icon: "🔬", label: context.tr(en: "Disease Expert", si: "රෝග විශේෂඥ", ta: "நோய் நிபுணர்"), earned: scanCount >= 200),
      _Achievement(icon: "⭐", label: context.tr(en: "Top Farmer", si: "විශිෂ්ට ගොවියා", ta: "சிறந்த விவசாயி"), earned: scanCount >= 500),
    ];

    final settings = [
      _Setting(
        icon: "🔔",
        label: context.tr(en: "Notifications", si: "දැනුම්දීම්", ta: "அறிவிப்புகள்"),
        sub: context.tr(en: "Disease alerts & tips", si: "රෝග අනතුරු ඇඟවීම් සහ උපදෙස්", ta: "நோய் எச்சரிக்கைகள் & குறிப்புகள்"),
        toggle: true,
        on: _notificationsOn,
      ),
      _Setting(
        icon: "📍",
        label: context.tr(en: "Location", si: "ස්ථානය", ta: "இடம்"),
        sub: locationState.isLoading
            ? context.tr(en: "Locating...", si: "ස්ථානය සොයමින්...", ta: "கண்டறியப்படுகிறது...")
            : locationState.address,
        toggle: true,
        on: _locationOn,
      ),
      _Setting(
        icon: "🌐",
        label: context.tr(en: "Language", si: "භාෂාව", ta: "மொழி"),
        sub: languageLabel,
        toggle: false,
      ),
      _Setting(
        icon: "📱",
        label: context.tr(en: "Offline Mode", si: "නොබැඳි ක්‍රමය", ta: "ஆஃப்லைன் பயன்முறை"),
        sub: context.tr(en: "Scan without internet", si: "අන්තර්ජාලය නොමැතිව ස්කෑන් කරන්න", ta: "இணையம் இல்லாமல் ஸ்கேன் செய்"),
        toggle: true,
        on: _offlineOn,
      ),
      _Setting(
        icon: "📞",
        label: context.tr(en: "Emergency Contact", si: "හදිසි ඇමතුම්", ta: "அவசர தொடர்பு"),
        sub: "0771 234 567",
        toggle: false,
      ),
      _Setting(
        icon: "❓",
        label: context.tr(en: "Help & Support", si: "උදව් සහ සහාය", ta: "உதவி & ஆதரவு"),
        sub: context.tr(en: "FAQs and tutorials", si: "නිතර අසන ප්‍රශ්න සහ නිබන්ධන", ta: "அடிக்கடி கேட்கப்படும் கேள்விகள்"),
        toggle: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(en: 'Profile', si: 'පැතිකඩ', ta: 'சுயவிவரம்'),
                    style: AppTextStyles.headlineMedium.copyWith(letterSpacing: -0.5, fontSize: 24),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LanguageSelectorButton(isCompact: true),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ]),
                          child: const Icon(Icons.settings_outlined, color: AppColors.settingsIcon, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(ref, scanCount),
                    _buildAchievements(achievements),
                    _buildFarmDetails(ref),
                    _buildSettings(settings),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: GestureDetector(
                        onTap: () async {
                          // Clear while the user id is still known.
                          await clearCachedUserRole();
                          try {
                            await Supabase.instance.client.auth.signOut();
                          } catch (e) {
                            debugPrint('Sign out error: $e');
                          }
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: AppColors.signOutBg, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: Text(
                            context.tr(en: 'Sign Out', si: 'පිටවීම', ta: 'வெளியேறு'),
                            style: const TextStyle(color: AppColors.signOutText, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(WidgetRef ref, int scanCount) {
    final userData = ref.watch(userProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: AppGradients.profileCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: userData.imagePath != null && userData.imagePath!.isNotEmpty
                            ? ((userData.imagePath!.startsWith('http') || kIsWeb)
                                ? Image.network(userData.imagePath!, fit: BoxFit.cover)
                                : Image.file(File(userData.imagePath!), fit: BoxFit.cover))
                            : Container(
                                color: Colors.white.withValues(alpha: 0.2),
                                child: Center(
                                  child: Text(
                                    userData.fullName.isNotEmpty ? userData.fullName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData.fullName.isNotEmpty ? userData.fullName : 'Unknown Farmer', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontSize: 20)),
                          const SizedBox(height: 2),
                          Text('${userData.farmName.isNotEmpty ? userData.farmName : 'Independent Farmer'} · ${userData.district.isNotEmpty ? userData.district : 'Unknown Zone'}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                                child: const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                              ),
                              const SizedBox(width: 4),
                              Text('Active Member', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildProfileStat(scanCount.toString(), 'Total Scans')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProfileStat(userData.farmSize.isNotEmpty ? userData.farmSize : '0', 'Acres Managed')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProfileStat(userData.primaryCrops.length.toString(), 'Crops Grown')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(val, style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontSize: 18)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAchievements(List<_Achievement> achievements) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(en: 'Achievements', si: 'ජයග්‍රහණ', ta: 'සாதனைகள்'), style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95),
            itemCount: achievements.length,
            itemBuilder: (context, i) {
              final a = achievements[i];
              return Opacity(
                opacity: a.earned ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: a.earned ? Colors.white : AppColors.achievementInactive,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (a.earned) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(a.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(color: a.earned ? AppColors.textPrimary : AppColors.settingsIcon, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                      if (a.earned) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(color: AppColors.achievementBadge, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetails(WidgetRef ref) {
    final userData = ref.watch(userProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(context.tr(en: 'Farm Details', si: 'ගොවිපල විස්තර', ta: 'பண்ணை விவரங்கள்'), style: AppTextStyles.titleSmall),
            ),
            const Divider(color: AppColors.dividerSubtle, height: 1),
            _buildDetailRow(context.tr(en: 'Farm Name', si: 'ගොවිපලේ නම', ta: 'பண்ணை பெயர்'), userData.farmName),
            const Divider(color: AppColors.dividerSubtle, height: 1),
            _buildDetailRow(context.tr(en: 'Location', si: 'ස්ථානය', ta: 'இடம்'), userData.district),
            const Divider(color: AppColors.dividerSubtle, height: 1),
            _buildDetailRow(context.tr(en: 'Main Crops', si: 'ප්‍රධාන බෝග', ta: 'முக்கிய பயிர்கள்'), userData.primaryCrops.isNotEmpty ? userData.primaryCrops.join(', ') : 'Not set'),
            const Divider(color: AppColors.dividerSubtle, height: 1),
            _buildDetailRow(context.tr(en: 'Farm Size', si: 'ගොවිපලේ ප්‍රමාණය', ta: 'பண்ணை அளவு'), userData.farmSize.isNotEmpty ? '${userData.farmSize} Acres' : 'Not set'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(List<_Setting> settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(en: 'Settings', si: 'සැකසීම්', ta: 'அமைப்புகள்'), style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: List.generate(settings.length, (i) {
                final s = settings[i];
                return Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (s.label == "Language" || s.icon == "🌐" || s.label.contains("භාෂාව") || s.label.contains("மொழி")) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Text(s.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.label, style: AppTextStyles.titleSmall.copyWith(fontSize: 14)),
                                  Text(s.sub, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                            if (s.toggle)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (i == 0) _notificationsOn = !_notificationsOn;
                                    if (i == 1) _locationOn = !_locationOn;
                                    if (i == 3) _offlineOn = !_offlineOn;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 44,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: s.on ? AppColors.primary : AppColors.settingsToggleOff,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        top: 4,
                                        left: s.on ? 22 : 4,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1))],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppColors.settingsChevron, size: 20),
                          ],
                        ),
                      ),
                    ),
                    if (i < settings.length - 1) const Divider(color: AppColors.dividerSubtle, height: 1),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String icon, label;
  final bool earned;
  const _Achievement({required this.icon, required this.label, required this.earned});
}

class _Setting {
  final String icon, label, sub;
  final bool toggle;
  bool on;
  _Setting({required this.icon, required this.label, required this.sub, required this.toggle, this.on = false});
}
