import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/tips/presentation/screens/tips_feed_screen.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';

class TipDetailScreen extends StatelessWidget {
  final FarmingTip tip;
  const TipDetailScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final code = AppStrings.currentLocaleCode;
    final title = tip.title(code);
    final body = tip.body(code);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Farming Tip', si: 'ගොවි උපදෙස', ta: 'விவசாய குறிப்பு')),
        actions: [
          IconButton(
            tooltip: context.tr(en: 'Share', si: 'බෙදාගන්න', ta: 'பகிர்'),
            icon: const Icon(Icons.share_rounded),
            onPressed: () => SharePlus.instance.share(ShareParams(text: '$title\n\n$body\n\n— Lumina farming tips', subject: title)),
          ),
          const LanguageSelectorButton(isCompact: true),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(context.trCrop(tip.crop)), backgroundColor: AppColors.primary.withValues(alpha: 0.1), side: BorderSide.none),
              if (tip.season.isNotEmpty && tip.season != 'Any')
                Chip(label: Text(context.trSeason(tip.season)), backgroundColor: AppColors.primary.withValues(alpha: 0.1), side: BorderSide.none),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.headlineMedium.copyWith(fontSize: 22, height: 1.3)),
          const SizedBox(height: 16),
          Text(body, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
          if (code == 'ta') ...[
            const SizedBox(height: 16),
            Text(
              'தமிழ் மொழிபெயர்ப்பு விரைவில் வரும்.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
