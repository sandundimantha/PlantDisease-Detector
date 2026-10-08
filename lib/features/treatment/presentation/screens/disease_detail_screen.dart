import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/features/treatment/data/disease_model.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'dart:ui';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_detail_screen.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final Disease disease;
  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final info = DiseaseCatalog.lookup(disease.name);
    final steps = info?.treatments ?? [for (final t in disease.treatments) DiseaseStep(t, '')];
    final overview = info == null ? disease.description : _overview(context, info);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            actions: const [
              LanguageSelectorButton(isDark: true, isCompact: true),
            ],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 64, bottom: 16, end: 24), // clear the back button when collapsed
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trDisease(disease.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'disease_img_${disease.id}',
                    child: SmartImage(
                      src: disease.imageUrl.isEmpty ? 'assets/images/hero_leaf.jpg' : disease.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradient overlay for text readability
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _buildQuickBadge(Icons.grass_rounded, context.trCrop(disease.cropName), AppColors.primary),
                      const SizedBox(width: 12),
                      _buildQuickBadge(Icons.warning_amber_rounded, context.trSeverity(disease.severityLabel), disease.severityColor),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(context.tr(en: 'Overview', si: 'දළ විශ්ලේෂණය', ta: 'கண்ணோட்டம்'), style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(overview, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 32),

                  // Symptoms
                  _buildSectionHeader(context.tr(en: 'Symptoms', si: 'රෝග ලක්ෂණ', ta: 'அறிகுறிகள்'), Icons.coronavirus_outlined, Colors.red.shade400),
                  const SizedBox(height: 12),
                  ...disease.symptoms.map((s) => _buildBulletPoint(context.trSymptom(s))),
                  const SizedBox(height: 32),

                  // Causes
                  _buildSectionHeader(context.tr(en: 'Causes & Spread', si: 'හේතු සහ ව්‍යාප්තිය', ta: 'காரணங்கள் & பரவல்'), Icons.air_rounded, Colors.blue.shade400),
                  const SizedBox(height: 12),
                  ...disease.causes.map((c) => _buildBulletPoint(context.trSymptom(c))),
                  const SizedBox(height: 32),

                  // Treatments (Timeline format)
                  _buildSectionHeader(context.tr(en: 'Treatment Plan', si: 'ප්‍රතිකාර සැලැස්ම', ta: 'சிகிச்சை திட்டம்'), Icons.medical_services_outlined, AppColors.primary),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: List.generate(steps.length, (index) {
                        return _buildTreatmentStep(
                          index + 1,
                          context.trTreatment(steps[index].title),
                          steps[index].desc.isEmpty ? null : context.trTreatment(steps[index].desc),
                          isLast: index == steps.length - 1,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TreatmentDetailScreen(diseaseName: disease.name, cropName: disease.cropName)),
                      ),
                      icon: const Icon(Icons.healing_rounded, color: Colors.white),
                      label: Text(
                        context.tr(en: 'Open Treatment Plan', si: 'ප්‍රතිකාර සැලැස්ම විවෘත කරන්න', ta: 'சிகிச்சைத் திட்டத்தைத் திறக்கவும்'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _overview(BuildContext context, DiseaseInfo info) {
    final cause = context.tr(
      en: '${context.trDisease(info.label)} is caused by ${info.pathogen}.',
      si: '${context.trDisease(info.label)} ඇති වන්නේ ${info.pathogen} නිසාය.',
      ta: '${context.trDisease(info.label)} ${info.pathogen} மூலம் ஏற்படுகிறது.',
    );
    final control = info.treatable
        ? context.tr(
            en: 'It can be controlled if you act early. Follow the steps below.',
            si: 'ඉක්මනින් ක්‍රියා කළහොත් එය පාලනය කළ හැක. පහත පියවර අනුගමනය කරන්න.',
            ta: 'விரைவில் செயல்பட்டால் இதைக் கட்டுப்படுத்தலாம். கீழே உள்ள படிகளைப் பின்பற்றவும்.',
          )
        : context.tr(
            en: 'There is no cure once a plant is infected. Remove infected plants and protect healthy ones.',
            si: 'පැලයක් ආසාදනය වූ පසු සුවයක් නැත. ආසාදිත පැල ඉවත් කර නිරෝගී පැල ආරක්ෂා කරන්න.',
            ta: 'ஒரு செடி பாதிக்கப்பட்டால் குணப்படுத்த முடியாது. பாதிக்கப்பட்ட செடிகளை அகற்றி ஆரோக்கியமானவற்றைப் பாதுகாக்கவும்.',
          );
    return '$cause $control';
  }

  Widget _buildQuickBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildTreatmentStep(int step, String text, String? detail, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontWeight: detail == null ? FontWeight.normal : FontWeight.w700,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 4),
                    Text(detail, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
