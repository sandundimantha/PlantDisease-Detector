import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_reminder_screen.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';

class TreatmentDetailScreen extends StatefulWidget {
  final String diseaseName;
  final String cropName;

  const TreatmentDetailScreen({
    super.key,
    this.diseaseName = 'Early Blight',
    this.cropName = 'Tomato',
  });

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Organic', 'Chemical', 'Cultural'];

  // Checkbox state for tasks: map key = '$tabIndex-$taskIndex'
  final Map<String, bool> _stepStates = {};

  final Map<int, List<Map<String, dynamic>>> _treatmentTasks = {
    0: [
      {
        'title': 'Neem Leaf Extract Spray',
        'subtitle': 'Mix 50ml neem oil in 10L water with soap',
        'time': 'Early Morning',
        'cost': 'Rs. 450',
        'icon': Icons.eco_rounded,
      },
      {
        'title': 'Prune Diseased Foliage',
        'subtitle': 'Sterilize shears, remove bottom 30cm leaves',
        'time': '7:30 AM',
        'cost': 'Free',
        'icon': Icons.content_cut_rounded,
      },
      {
        'title': 'Wood Ash Soil Dusting',
        'subtitle': 'Dust dry ash around root zones to balance pH',
        'time': 'Evening',
        'cost': 'Rs. 150',
        'icon': Icons.grass_rounded,
      },
      {
        'title': 'Trichoderma Bio-Agent',
        'subtitle': 'Incorporate antagonistic bio-culture into compost',
        'time': 'Weekly',
        'cost': 'Rs. 850',
        'icon': Icons.science_outlined,
      },
    ],
    1: [
      {
        'title': 'Copper Oxychloride 50 WP',
        'subtitle': 'Apply 30g per 10L water on whole canopy',
        'time': '7:00 AM (Calm wind)',
        'cost': 'Rs. 1,450',
        'icon': Icons.water_drop_outlined,
      },
      {
        'title': 'Mancozeb 75% WG Spray',
        'subtitle': 'Alternate with copper spray to prevent resistance',
        'time': 'Every 10 days',
        'cost': 'Rs. 1,200',
        'icon': Icons.medication_liquid_rounded,
      },
      {
        'title': 'Wear Certified PPE Gear',
        'subtitle': 'Safety goggles, N95 respirator, and rubber gloves',
        'time': 'Before spraying',
        'cost': 'Rs. 850',
        'icon': Icons.shield_outlined,
      },
      {
        'title': 'Observe Pre-Harvest Interval (PHI)',
        'subtitle': 'Wait minimum 7 days before picking tomatoes',
        'time': '7 Days Waiting',
        'cost': 'Crucial',
        'icon': Icons.timer_outlined,
      },
    ],
    2: [
      {
        'title': 'Install Drip Irrigation',
        'subtitle': 'Direct water strictly to soil; avoid wet foliage',
        'time': 'Continuous',
        'cost': 'Rs. 2,200',
        'icon': Icons.opacity_rounded,
      },
      {
        'title': 'Ensure 60cm Plant Spacing',
        'subtitle': 'Promotes aeration and fast drying of dew',
        'time': 'Planting stage',
        'cost': 'Free',
        'icon': Icons.space_bar_rounded,
      },
      {
        'title': 'Stake & Trellis Vines',
        'subtitle': 'Elevate leaves above soil splash pathogens',
        'time': 'Growth stage',
        'cost': 'Rs. 500',
        'icon': Icons.fence_rounded,
      },
      {
        'title': 'Crop Rotation with Legumes',
        'subtitle': 'Do not plant Solanaceae crops consecutively',
        'time': 'Next Season',
        'cost': 'Free',
        'icon': Icons.sync_rounded,
      },
    ],
  };

  final Map<int, List<Map<String, String>>> _recommendedProducts = {
    0: [
      {
        'name': 'Bio Neem Oil 250ml',
        'price': 'Rs. 950',
        'image': 'https://images.unsplash.com/photo-1608687352332-9c3f1debc347?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'Organic Compost 5kg',
        'price': 'Rs. 650',
        'image': 'https://images.unsplash.com/photo-1627920769931-50e42f9e403d?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'Trichoderma Harzianum 500g',
        'price': 'Rs. 850',
        'image': 'https://images.unsplash.com/photo-1584483789066-50ba68dd6531?q=80&w=200&auto=format&fit=crop',
      },
    ],
    1: [
      {
        'name': 'Copper Fungicide 500g',
        'price': 'Rs. 1,450',
        'image': 'https://images.unsplash.com/photo-1584483789066-50ba68dd6531?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'Mancozeb 75% WG 500g',
        'price': 'Rs. 1,200',
        'image': 'https://images.unsplash.com/photo-1627920769931-50e42f9e403d?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'N95 Respirator + Gloves Set',
        'price': 'Rs. 850',
        'image': 'https://images.unsplash.com/photo-1584483789066-50ba68dd6531?q=80&w=200&auto=format&fit=crop',
      },
    ],
    2: [
      {
        'name': 'Drip Irrigation Kit (50m)',
        'price': 'Rs. 2,200',
        'image': 'https://images.unsplash.com/photo-1584483789066-50ba68dd6531?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'Bypass Pruning Shears',
        'price': 'Rs. 1,950',
        'image': 'https://images.unsplash.com/photo-1416879598555-46e38bc86445?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'Bamboo Trellis Stakes (x10)',
        'price': 'Rs. 600',
        'image': 'https://images.unsplash.com/photo-1627920769931-50e42f9e403d?q=80&w=200&auto=format&fit=crop',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tasks = _treatmentTasks[_selectedTabIndex] ?? [];
    final products = _recommendedProducts[_selectedTabIndex] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Premium Image Header ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${context.trDisease(widget.diseaseName)} ${context.tr(en: 'Plan', si: 'සැලැස්ම', ta: 'திட்டம்')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const SmartImage(
                        src: 'https://images.unsplash.com/photo-1592424001815-32e6040ea468?q=80&w=800&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                      // Dark gradient overlay for text readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview / Estimated Cost Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.copper.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.monetization_on_outlined, color: AppColors.copper, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTabIndex == 0
                                        ? '${context.tr(en: 'Est. Cost', si: 'ඇස්තමේන්තු පිරිවැය', ta: 'மதிப்பிடப்பட்ட செலவு')}: Rs. 950 - 1,450'
                                        : (_selectedTabIndex == 1
                                            ? '${context.tr(en: 'Est. Cost', si: 'ඇස්තමේන්තු පිරිවැය', ta: 'மதிப்பிடப்பட்ட செலவு')}: Rs. 2,650'
                                            : '${context.tr(en: 'Est. Cost', si: 'ඇස්තමේන්තු පිරිවැය', ta: 'மதிப்பிடப்பட்ட செலவு')}: Rs. 0 - 2,200'),
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${context.tr(en: 'Crop', si: 'බෝගය', ta: 'பயிர்')}: ${context.trCrop(widget.cropName)} • ${context.tr(en: 'Complete Recovery ~14 days', si: 'සම්පූර්ණ සුවය ~දින 14', ta: 'முழுமையான மீட்பு ~14 நாட்கள்')}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Segmented Tabs: Organic / Chemical / Cultural
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isSelected = _selectedTabIndex == index;
                            final tabLabels = [
                              context.tr(en: 'Organic', si: 'කාබනික', ta: 'இயற்கை'),
                              context.tr(en: 'Chemical', si: 'රසායනික', ta: 'இரசாயன'),
                              context.tr(en: 'Cultural', si: 'කෘෂිකාර්මික', ta: 'பயிற்சி முறை'),
                            ];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tabLabels[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step-by-step Treatment Tasks
                      Text(
                        context.tr(en: 'Step-by-Step Action Plan', si: 'පියවරෙන් පියවර ක්‍රියාකාරී සැලැස්ම', ta: 'படிபடியான செயல் திட்டம்'),
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Column(
                        children: List.generate(tasks.length, (index) {
                          final task = tasks[index];
                          final key = '$_selectedTabIndex-$index';
                          final isDone = _stepStates[key] ?? false;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _stepStates[key] = !isDone;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppColors.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDone ? AppColors.copper : AppColors.cardBorder,
                                  width: isDone ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isDone ? AppColors.copper : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'] as String,
                                          style: AppTextStyles.titleSmall.copyWith(
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color: isDone
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          task['subtitle'] as String,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.cardSurface,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task['time'] as String,
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              task['cost'] as String,
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.copper,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Recommended Sri Lankan Agricultural Products
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(en: 'Recommended Inputs (LKR)', si: 'නිර්දේශිත ද්‍රව්‍ය (රු.)', ta: 'பரிந்துரைக்கப்பட்ட பொருட்கள் (ரூ.)'),
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text('Sri Lanka Ag', style: AppTextStyles.bodySmall.copyWith(color: AppColors.copper, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 104,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: products.length,
                          itemBuilder: (context, idx) {
                            final prod = products[idx];
                            return _buildProductCard(
                              prod['name']!,
                              prod['price']!,
                              prod['image']!,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 120), // Bottom button clearance
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Button: Schedule Reminder
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreatmentReminderScreen(
                            treatmentTitle: '${_tabs[_selectedTabIndex]} Treatment',
                            diseaseName: widget.diseaseName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.alarm_rounded, color: Colors.white),
                    label: Text(
                      context.tr(en: 'Schedule Treatment Reminder', si: 'ප්‍රතිකාර මතක් කිරීමක් සකසන්න', ta: 'சிகிச்சை நினைவூட்டலை திட்டமிடுங்கள்'),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String name, String price, String imageUrl) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SmartImage(
              src: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.copper,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
