import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  int _selectedFilterIndex = 0;
  final List<Map<String, dynamic>> _filters = [
    {'title': 'Trending', 'icon': Icons.local_fire_department_rounded},
    {'title': 'My Crops', 'icon': Icons.eco_rounded},
    {'title': 'Q&A', 'icon': Icons.help_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(context.tr(en: 'Community Forum', si: 'ගොවි සංසදය', ta: 'விவசாயிகள் மன்றம்'), style: AppTextStyles.titleMedium),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      hintText: context.tr(en: 'Search discussions...', si: 'සාකච්ඡා සොයන්න...', ta: 'விவாதங்களைத் தேடுங்கள்...'),
                      hintStyle: AppTextStyles.bodyMedium,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter Tabs
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    final filterTitles = [
                      context.tr(en: 'Trending', si: 'ජනප්‍රිය', ta: 'பிரபலமானது'),
                      context.tr(en: 'My Crops', si: 'මගේ බෝග', ta: 'என் பயிர்கள்'),
                      context.tr(en: 'Q&A', si: 'ප්‍රශ්නෝත්තර', ta: 'கேள்வி & பதில்'),
                    ];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: Colors.grey.shade400),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _filters[index]['icon'],
                              size: 18,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filterTitles[index],
                              style: AppTextStyles.titleSmall.copyWith(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Feed List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _buildFeedCard(
                      'Farmer Tom',
                      '3h ago',
                      'First signs of blight on my tomatoes... need advice ASAP.',
                      15,
                      4,
                      'https://images.unsplash.com/photo-1592878904946-b3cd8ae243d0?q=80&w=200&auto=format&fit=crop',
                      'https://images.unsplash.com/photo-1582298538104-fe2e74c878f1?q=80&w=300&auto=format&fit=crop', // Tomato blight
                    ),
                    _buildFeedCard(
                      'Green_Thumb',
                      '5h ago',
                      'Thinking of rotating my corn crop this season. Pros and cons?',
                      8,
                      2,
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
                      'https://images.unsplash.com/photo-1601646271927-466d6a2f8c05?q=80&w=300&auto=format&fit=crop', // Corn field
                    ),
                    _buildFeedCard(
                      'AgriExpert',
                      '1d ago',
                      'New fertilizer comparison study published today. Very interesting results for wheat yields.',
                      42,
                      12,
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
                      null, // No image
                    ),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ],
          ),
          
          // Centered FAB for New Post
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(String username, String timeAgo, String content, int upvotes, int comments, String avatarUrl, String? contentImageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(width: 12),
              Text(username, style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(timeAgo, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  content,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.4),
                ),
              ),
              if (contentImageUrl != null) ...[
                const SizedBox(width: 16),
                SmartImage(
                  src: contentImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInteractionButton(Icons.arrow_upward_rounded, '$upvotes ${context.tr(en: 'Upvotes', si: 'මනාප', ta: 'வாக்குகள்')}'),
              const SizedBox(width: 24),
              _buildInteractionButton(Icons.chat_bubble_outline_rounded, '$comments ${context.tr(en: 'Comments', si: 'අදහස්', ta: 'கருத்துகள்')}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
