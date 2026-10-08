import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/treatment/data/disease_model.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_detail_screen.dart';

class DiseaseComparisonScreen extends StatelessWidget {
  final Disease? diseaseA;
  final Disease? diseaseB;

  const DiseaseComparisonScreen({
    super.key,
    this.diseaseA,
    this.diseaseB,
  });

  // Two look-alike diseases, shown when nothing was picked in the library
  static final Disease _fallbackA = Disease.fromCatalog(DiseaseCatalog.lookup('Tomato Early Blight')!);
  static final Disease _fallbackB = Disease.fromCatalog(DiseaseCatalog.lookup('Tomato Late Blight')!);

  @override
  Widget build(BuildContext context) {
    final a = diseaseA ?? _fallbackA;
    final b = diseaseB ?? _fallbackB;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
        title: Text(
          context.tr(
            en: 'Side-by-Side Comparison',
            si: 'සංසන්දනය',
            ta: 'பக்கவாட்டு ஒப்பீடு',
          ),
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          LanguageSelectorButton(isDark: true, isCompact: true),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Subtitle banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.06),
              child: Text(
                context.tr(
                  en: 'Visually similar symptoms can cause misdiagnosis. Review key diagnostic differences below.',
                  si: 'සමාන රෝග ලක්ෂණ නිසා වැරදි නිගමන ඇති විය හැක. පහත ප්‍රධාන වෙනස්කම් බලන්න.',
                  ta: 'ஒத்த அறிகுறிகள் தவறான நோயறிதலை ஏற்படுத்தலாம். முக்கிய வேறுபாடுகளை கீழே காண்க.',
                ),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ),

            // Top Side-by-Side Photo & Title Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildHeaderCard(context, a, isLeft: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildHeaderCard(context, b, isLeft: false)),
                ],
              ),
            ),

            // Comparison Sections
            _buildComparisonSection(
              context,
              title: context.tr(
                en: 'Key Visual Symptoms',
                si: 'ප්‍රධාන දෘශ්‍ය රෝග ලක්ෂණ',
                ta: 'முக்கிய காட்சி அறிகுறிகள்',
              ),
              icon: Icons.visibility_rounded,
              contentA: a.symptoms,
              contentB: b.symptoms,
            ),

            _buildComparisonSection(
              context,
              title: context.tr(
                en: 'Causes & Environmental Spread',
                si: 'හේතු සහ පාරිසරික ව්‍යාප්තිය',
                ta: 'காரணங்கள் மற்றும் சுற்றுச்சூழல் பரவல்',
              ),
              icon: Icons.air_rounded,
              contentA: a.causes,
              contentB: b.causes,
            ),

            _buildComparisonSection(
              context,
              title: context.tr(
                en: 'Recommended Treatments & Pricing',
                si: 'නිර්දේශිත ප්‍රතිකාර සහ මිල ගණන්',
                ta: 'பரிந்துரைக்கப்பட்ட சிகிச்சைகள் & விலை',
              ),
              icon: Icons.healing_rounded,
              contentA: a.treatments,
              contentB: b.treatments,
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TreatmentDetailScreen(diseaseName: a.name, cropName: a.cropName)),
                  );
                },
                icon: const Icon(Icons.medication_rounded, color: Colors.white),
                label: Text(
                  context.tr(
                    en: 'View Full Treatment Plan',
                    si: 'සම්පූර්ණ ප්‍රතිකාර සැලැස්ම බලන්න',
                    ta: 'முழு சிகிச்சை திட்டத்தைக் காண்க',
                  ),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Disease d, {required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: d.imageUrl.isEmpty
                ? Container(
                    height: 120,
                    color: d.severityColor.withValues(alpha: 0.12),
                    child: Icon(Icons.eco_rounded, color: d.severityColor, size: 44),
                  )
                : SmartImage(
                    src: d.imageUrl,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.trCrop(d.cropName).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.trDisease(d.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: d.severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.trSeverity(d.severityLabel),
                      style: TextStyle(color: d.severityColor, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> contentA,
    required List<String> contentB,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: contentA.map((item) => _buildBulletItem(context, item)).toList(),
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: contentB.map((item) => _buildBulletItem(context, item)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(BuildContext context, String text) {
    final translated = context.trSymptom(text);
    final displayText = translated != text ? translated : context.trTreatment(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              displayText,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
