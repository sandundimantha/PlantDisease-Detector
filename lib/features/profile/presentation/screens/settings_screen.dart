import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/language_selection_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    String languageLabel = 'English';
    if (currentLocale.languageCode == 'si') {
      languageLabel = 'සිංහල';
    } else if (currentLocale.languageCode == 'ta') {
      languageLabel = 'தமிழ்';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr(en: 'Settings', si: 'සැකසීම්', ta: 'அமைப்புகள்'),
          style: AppTextStyles.titleMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            context.tr(en: 'General', si: 'සාමාන්‍ය', ta: 'பொதுவானவை'),
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.language_rounded,
            context.tr(en: 'Language', si: 'භාෂාව', ta: 'மொழி'),
            languageLabel,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.notifications_none_rounded,
            context.tr(en: 'Notifications', si: 'දැනුම්දීම්', ta: 'அறிவிப்புகள்'),
            context.tr(en: 'Enabled', si: 'සක්‍රියයි', ta: 'இயக்கப்பட்டது'),
            onTap: () {},
          ),
          _buildSettingsTile(
            Icons.dark_mode_outlined,
            context.tr(en: 'Dark Mode', si: 'අඳුරු තේමාව', ta: 'இருண்ட பயன்முறை'),
            context.tr(en: 'Off (System)', si: 'ක්‍රියාවිරහිතයි', ta: 'முடக்கப்பட்டது'),
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          Text(
            context.tr(en: 'Support & Legal', si: 'සහාය සහ නීතිමය', ta: 'ஆதரவு & சட்டம்'),
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            Icons.help_outline_rounded,
            context.tr(en: 'Help Center', si: 'උපකාරක මධ්‍යස්ථානය', ta: 'உதவி மையம்'),
            null,
            onTap: () {},
          ),
          _buildSettingsTile(
            Icons.privacy_tip_outlined,
            context.tr(en: 'Privacy Policy', si: 'රහස්‍යතා ප්‍රතිපත්තිය', ta: 'தனியுரிமைக் கொள்கை'),
            null,
            onTap: () {},
          ),
          _buildSettingsTile(
            Icons.description_outlined,
            context.tr(en: 'Terms of Service', si: 'සේවා කොන්දේසි', ta: 'சேவை விதிமுறைகள்'),
            null,
            onTap: () {},
          ),

          const SizedBox(height: 48),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Delete account logic
              },
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              label: Text(
                context.tr(en: 'Delete Account', si: 'ගිණුම මකන්න', ta: 'கணக்கை நீக்கு'),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('CropGuard LK v1.0.0', style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String? trailingText, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.titleMedium),
        trailing: trailingText != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trailingText, style: AppTextStyles.bodyMedium),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              )
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
