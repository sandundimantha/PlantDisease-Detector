import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String _selectedCode = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'localName': 'English'},
    {'code': 'si', 'name': 'Sinhala', 'localName': 'සිංහල'},
    {'code': 'ta', 'name': 'Tamil', 'localName': 'தமிழ்'},
  ];

  @override
  void initState() {
    super.initState();
    // Reflect whatever locale is already saved
    _selectedCode = ref.read(localeProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selectedCode == 'si'
                    ? 'ඔබේ භාෂාව තෝරන්න'
                    : (_selectedCode == 'ta'
                        ? 'உங்கள் மொழியை தேர்ந்தெடுக்கவும்'
                        : 'Choose your language'),
                style: AppTextStyles.headlineMedium.copyWith(
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedCode == 'si'
                    ? 'ඔබට මෙය සැකසුම් වලින් පසුව වෙනස් කළ හැකිය.'
                    : (_selectedCode == 'ta'
                        ? 'இதை பின்னர் அமைப்புகளில் மாற்றலாம்.'
                        : 'Select your preferred language. You can change this anytime.'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              ..._languages.map((lang) =>
                  _buildLanguageCard(lang['code']!, lang['name']!, lang['localName']!)),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  // Persist & propagate the chosen locale via Riverpod
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(_selectedCode));
                  if (mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/onboarding');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedCode == 'si'
                          ? 'ඉදිරියට යන්න'
                          : (_selectedCode == 'ta' ? 'தொடரவும்' : 'Continue'),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(String code, String name, String localName) {
    final bool isSelected = _selectedCode == code;

    return GestureDetector(
      onTap: () async {
        setState(() => _selectedCode = code);
        await ref.read(localeProvider.notifier).setLocale(Locale(code));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.copper : AppColors.cardBorder,
            width: isSelected ? 2.5 : 1.2,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.copper.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localName,
                    style: TextStyle(
                      fontFamily: 'NotoSansSinhala',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? AppColors.copper : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.copper : AppColors.textSecondary.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected ? AppColors.copper : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
