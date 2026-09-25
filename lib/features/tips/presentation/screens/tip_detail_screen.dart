import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';

class TipDetailScreen extends StatelessWidget {
  const TipDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SmartImage(
                src: 'https://images.unsplash.com/photo-1628183189955-467f53a25301?w=800&h=400&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Yala Season', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Oct 12, 2026', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Best practices for soil preparation before planting tomatoes.',
                    style: AppTextStyles.headlineLarge.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '1. Soil Testing and Adjustment\n'
                    'Before planting, it is crucial to test your soil pH. Tomatoes thrive in slightly acidic soil (pH 6.0 to 6.8). Based on the results, you might need to add lime to raise the pH or sulfur to lower it.\n\n'
                    '2. Deep Plowing\n'
                    'Plow the soil deeply (at least 8-10 inches) to loosen compaction. This allows the root systems to penetrate easily, ensuring better water and nutrient absorption.\n\n'
                    '3. Adding Organic Matter\n'
                    'Mix well-rotted compost or aged manure into the topsoil. Organic matter improves soil structure, moisture retention, and provides a slow release of nutrients throughout the growing season.\n\n'
                    '4. Solarization for Disease Control\n'
                    'If you had nematode or fungal issues in previous seasons, consider solarizing the soil. Cover moistened soil with clear plastic for 4-6 weeks during the hottest part of the year to kill soil-borne pathogens.\n\n'
                    'Conclusion\n'
                    'Taking the time to prepare your soil properly will drastically reduce the occurrence of diseases and lead to a more bountiful harvest.',
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 80), // Padding for scrolling
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
