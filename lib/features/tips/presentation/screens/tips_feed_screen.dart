import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/tips/presentation/screens/tip_detail_screen.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';

/// A farming tip from the `tips` table (English and Sinhala text).
class FarmingTip {
  final String id;
  final String crop;
  final String season;
  final String titleEn;
  final String bodyEn;
  final String titleSi;
  final String bodySi;
  final DateTime publishedAt;

  const FarmingTip({
    required this.id,
    required this.crop,
    required this.season,
    required this.titleEn,
    required this.bodyEn,
    required this.titleSi,
    required this.bodySi,
    required this.publishedAt,
  });

  factory FarmingTip.fromJson(Map<String, dynamic> j) => FarmingTip(
        id: j['id'].toString(),
        crop: j['crop'] ?? '',
        season: j['season'] ?? '',
        titleEn: j['title_en'] ?? j['title_si'] ?? '',
        bodyEn: j['body_en'] ?? j['body_si'] ?? '',
        titleSi: j['title_si'] ?? '',
        bodySi: j['body_si'] ?? '',
        publishedAt: DateTime.tryParse(j['published_at']?.toString() ?? '') ?? DateTime.now(),
      );

  /// Sinhala text when the app is in Sinhala; English otherwise (no Tamil text yet).
  String title(String code) => code == 'si' && titleSi.isNotEmpty ? titleSi : titleEn;
  String body(String code) => code == 'si' && bodySi.isNotEmpty ? bodySi : bodyEn;

  int get readMinutes => (bodyEn.split(' ').length / 180).ceil().clamp(1, 10);
}

final tipsProvider = FutureProvider.autoDispose<List<FarmingTip>>((ref) async {
  final rows = await Supabase.instance.client.from('tips').select().order('published_at', ascending: false);
  return (rows as List).map((r) => FarmingTip.fromJson(r)).toList();
});

class TipsFeedScreen extends ConsumerWidget {
  const TipsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(tipsProvider);
    final code = AppStrings.currentLocaleCode;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Farming Tips', si: 'ගොවි උපදෙස්', ta: 'விவசாய குறிப்புகள்')),
        actions: const [LanguageSelectorButton(isCompact: true)],
      ),
      body: tipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(context.tr(en: 'Could not load tips', si: 'උපදෙස් පූරණය කළ නොහැක', ta: 'குறிப்புகளை ஏற்ற முடியவில்லை'), style: AppTextStyles.titleSmall),
              TextButton(
                onPressed: () => ref.invalidate(tipsProvider),
                child: Text(context.tr(en: 'Retry', si: 'නැවත උත්සාහ කරන්න', ta: 'மீண்டும் முயற்சி')),
              ),
            ],
          ),
        ),
        data: (tips) {
          if (tips.isEmpty) {
            return Center(
              child: Text(context.tr(en: 'No tips yet', si: 'තවම උපදෙස් නැත', ta: 'இன்னும் குறிப்புகள் இல்லை'), style: AppTextStyles.bodyMedium),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(tipsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tips.length,
              itemBuilder: (context, i) {
                final tip = tips[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TipDetailScreen(tip: tip))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            _chip(context.trCrop(tip.crop)),
                            if (tip.season.isNotEmpty && tip.season != 'Any') _chip(tip.season),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(tip.title(code), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(tip.body(code), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              context.tr(en: '${tip.readMinutes} min read', si: 'මිනිත්තු ${tip.readMinutes} කියවීම', ta: '${tip.readMinutes} நிமிட வாசிப்பு'),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      );
}
