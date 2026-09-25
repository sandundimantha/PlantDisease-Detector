import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

class PhotoGuideScreen extends StatelessWidget {
  const PhotoGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr(
            en: 'How to take a good photo',
            si: 'හොඳ ඡායාරූපයක් ගන්නේ කෙසේද',
            ta: 'நல்ல புகைப்படம் எடுப்பது எப்படி',
          ),
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                en: 'Help our AI give you the best result by following these simple rules.',
                si: 'මෙම සරල නීති අනුගමනය කිරීමෙන් අපගේ AI වෙතින් නිවැරදිම ප්‍රතිඵලය ලබාගන්න.',
                ta: 'இந்த எளிய விதிகளைப் பின்பற்றி எங்கள் AI சிறந்த முடிவை வழங்க உதவுங்கள்.',
              ),
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            _buildGuideItem(
              title: context.tr(en: 'Get close to the leaf', si: 'පත්‍රයට සමීප වන්න', ta: 'இலைக்கு அருகில் செல்லவும்'),
              description: context.tr(en: 'Focus on a single infected leaf rather than the whole plant.', si: 'මුළු පැළයටම වඩා රෝගී වූ එක් පත්‍රයක් වෙත යොමු වන්න.', ta: 'முழு செடியை விட பாதிக்கப்பட்ட ஒரு இலையில் கவனம் செலுத்துங்கள்.'),
              isGood: true,
              icon: Icons.filter_center_focus_rounded,
            ),
            _buildGuideItem(
              title: context.tr(en: 'Avoid blurry photos', si: 'නොපැහැදිලි ඡායාරූප ගැනීමෙන් වළකින්න', ta: 'மங்கலான புகைப்படங்களைத் தவிர்க்கவும்'),
              description: context.tr(en: 'Keep your hands steady. Tap the screen to focus before shooting.', si: 'අත නොසොල්වා තබාගන්න. ඡායාරූපය ගැනීමට පෙර තිරය මත ස්පර්ශ කර focus කරන්න.', ta: 'கைகளை நிலையாக வைத்திருங்கள். எடுப்பதற்கு முன் ஃபோகஸ் செய்ய திரையைத் தட்டவும்.'),
              isGood: false,
              icon: Icons.blur_on_rounded,
            ),
            _buildGuideItem(
              title: context.tr(en: 'Good lighting is key', si: 'හොඳ ආලෝකය වැදගත් වේ', ta: 'நல்ல வெளிச்சம் முக்கியமானது'),
              description: context.tr(en: 'Avoid harsh shadows or taking photos against the sun.', si: 'තද සෙවනැලි හෝ හිරු එළියට විරුද්ධව ඡායාරූප ගැනීමෙන් වළකින්න.', ta: 'கடுமையான நிழல்கள் அல்லது சூரியனுக்கு எதிராக புகைப்படம் எடுப்பதைத் தவிர்க்கவும்.'),
              isGood: true,
              icon: Icons.wb_sunny_rounded,
            ),
            _buildGuideItem(
              title: context.tr(en: 'One leaf at a time', si: 'වරකට එක් පත්‍රයක් පමණි', ta: 'ஒரு முறைக்கு ஒரு இலை'),
              description: context.tr(en: 'Multiple leaves overlapping can confuse the AI model.', si: 'පත්‍ර කිහිපයක් එක මත එක වැටී තිබීම AI ආකෘතිය ව්‍යාකූල කළ හැක.', ta: 'பல இலைகள் ஒன்றன் மேல் ஒன்று இருப்பது AI மாதிரியை குழப்பலாம்.'),
              isGood: false,
              icon: Icons.content_copy_rounded,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                context.tr(en: 'Got it, let\'s scan!', si: 'තේරුණා, ස්කෑන් කරමු!', ta: 'புரிந்தது, ஸ்கேன் செய்வோம்!'),
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({required String title, required String description, required bool isGood, required IconData icon}) {
    final accentColor = isGood ? AppColors.severityDefault : AppColors.severityHigh;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(title, style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
