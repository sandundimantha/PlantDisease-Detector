import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:plant_disease_detector/features/community/application/community_provider.dart';
import 'package:plant_disease_detector/features/community/data/community_models.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class _ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const _ShimmerSkeleton({required this.width, required this.height, this.borderRadius = 8});

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.1, 0.5, 0.9],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
        );
      }
    );
  }
}

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  int _selectedFilterIndex = 0;
  bool _searching = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Applies the selected chip and the search text to the feed.
  /// Trending: most liked/commented first Â· My Crops: posts about the user's
  /// crops Â· Q&A: questions.
  List<CommunityPost> _visiblePosts(List<CommunityPost> posts, List<String> myCrops) {
    final q = _query.trim().toLowerCase();
    Iterable<CommunityPost> list = posts;
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.content.toLowerCase().contains(q) ||
          (p.title ?? '').toLowerCase().contains(q) ||
          (p.author?.fullName ?? '').toLowerCase().contains(q));
    }
    switch (_selectedFilterIndex) {
      case 0:
        return list.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 2:
        final crops = myCrops.map((c) => c.toLowerCase()).where((c) => c.isNotEmpty).toList();
        list = list.where((p) {
          if (p.category == 'My Crops') return true;
          final text = '${p.title ?? ''} ${p.content}'.toLowerCase();
          return crops.any(text.contains);
        });
      case 3:
        list = list.where((p) => p.category == 'Q&A' || p.content.contains('?') || (p.title ?? '').contains('?'));
      default:
        final sorted = list.toList()
          ..sort((a, b) {
            final byEngagement = (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount);
            return byEngagement != 0 ? byEngagement : b.createdAt.compareTo(a.createdAt);
          });
        return sorted;
    }
    return list.toList();
  }

  Future<void> _sharePost(CommunityPost post) async {
    final author = post.author?.fullName ?? 'A farmer';
    final title = post.title?.isNotEmpty == true ? '${post.title}\n' : '';
    await SharePlus.instance.share(ShareParams(
      text: '$title${post.content}\n\nâ€” $author, Lumina farmer community',
      subject: post.title ?? 'Lumina community post',
    ));
  }

  final List<Map<String, dynamic>> _filters = [
    {'title': 'Latest', 'icon': Icons.schedule_rounded},
    {'title': 'Trending', 'icon': Icons.local_fire_department_rounded},
    {'title': 'My Crops', 'icon': Icons.eco_rounded},
    {'title': 'Q&A', 'icon': Icons.help_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityFeedProvider);
    final userData = ref.watch(userProvider);
    final String displayName = userData.fullName.isNotEmpty ? userData.fullName : 'U';

    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Facebook-style grey background behind cards
      appBar: PremiumAppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.tr(en: 'Search posts', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸à·Š à·ƒà·œà¶ºà¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®•à®³à¯ˆà®¤à¯ à®¤à¯‡à®Ÿà¯'),
                  border: InputBorder.none,
                ),
              )
            : Text(context.tr(en: 'Farmer Community', si: 'à¶œà·œà·€à·’ à·ƒà¶‚à·ƒà¶¯à¶º', ta: 'à®µà®¿à®µà®šà®¾à®¯à®¿à®•à®³à¯ à®®à®©à¯à®±à®®à¯')),
        actions: [
          IconButton(
            tooltip: _searching
                ? context.tr(en: 'Close search', si: 'à·ƒà·™à·€à·“à¶¸ à·€à·ƒà¶±à·Šà¶±', ta: 'à®¤à¯‡à®Ÿà®²à¯ˆ à®®à¯‚à®Ÿà¯')
                : context.tr(en: 'Search', si: 'à·ƒà·œà¶ºà¶±à·Šà¶±', ta: 'à®¤à¯‡à®Ÿà¯'),
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchController.clear();
              }
            }),
          )
        ],
      ),
      body: postsAsync.when(
        data: (allPosts) {
          final posts = _visiblePosts(allPosts, userData.primaryCrops);
          return RefreshIndicator(
            onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // "What's on your mind?" Input (Facebook Style)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8), // Gap before feed
                    child: Row(
                      children: [
                        _buildUserAvatar(userData.imagePath, displayName, 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/create_post'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                context.tr(en: "What's on your mind?", si: "à¶”à¶¶à·š à¶…à¶¯à·„à·ƒ à¶šà·”à¶¸à¶šà·Šà¶¯?", ta: "à®‰à®™à¯à®•à®³à¯ à®®à®©à®¤à®¿à®²à¯ à®Žà®©à¯à®© à®‡à®°à¯à®•à¯à®•à®¿à®±à®¤à¯?"),
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.green),
                          onPressed: () => context.push('/create_post'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Tabs (LinkedIn/Insta style chips)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    height: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilterIndex == index;
                        final filterTitles = [
                          context.tr(en: 'Trending', si: 'à¶¢à¶±à¶´à·Šâ€à¶»à·’à¶º', ta: 'à®ªà®¿à®°à®ªà®²à®®à®¾à®©à®¤à¯'),
                          context.tr(en: 'My Crops', si: 'à¶¸à¶œà·š à¶¶à·à¶œ', ta: 'à®Žà®©à¯ à®ªà®¯à®¿à®°à¯à®•à®³à¯'),
                          context.tr(en: 'Q&A', si: 'à¶´à·Šâ€à¶»à·à·Šà¶±à·à¶­à·Šà¶­à¶»', ta: 'à®•à¯‡à®³à¯à®µà®¿ & à®ªà®¤à®¿à®²à¯'),
                        ];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilterIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _filters[index]['icon'],
                                  size: 16,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  filterTitles[index],
                                  style: TextStyle(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Feed List
                if (posts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nature_people_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            allPosts.isEmpty
                                ? context.tr(en: 'No posts yet', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸à·Š à¶šà·’à·ƒà·’à·€à¶šà·Š à¶±à·à¶­', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®•à®³à¯ à®Žà®¤à¯à®µà¯à®®à¯ à®‡à®²à¯à®²à¯ˆ')
                                : context.tr(en: 'No matching posts', si: 'à¶œà·à·…à¶´à·™à¶± à¶´à·…à¶šà·’à¶»à·“à¶¸à·Š à¶±à·à¶­', ta: 'à®ªà¯Šà®°à¯à®¨à¯à®¤à¯à®®à¯ à®‡à®Ÿà¯à®•à¯ˆà®•à®³à¯ à®‡à®²à¯à®²à¯ˆ'),
                            style: AppTextStyles.titleMedium.copyWith(color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(en: 'Be the first to share something with the community.', si: 'à¶´à·…à¶¸à·” à¶´à¶«à·’à·€à·’à¶©à¶º à¶‘à¶šà¶­à·” à¶šà¶»à¶±à·Šà¶±.', ta: 'à®šà®®à¯‚à®•à®¤à¯à®¤à¯à®Ÿà®©à¯ à®Žà®¤à¯ˆà®¯à®¾à®µà®¤à¯ à®®à¯à®¤à®²à®¿à®²à¯ à®ªà®•à®¿à®°à®µà¯à®®à¯.'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/create_post'),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: Text(context.tr(en: 'Create Post', si: 'à¶´à·… à¶šà¶»à¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆ à®‰à®°à¯à®µà®¾à®•à¯à®•à¯'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPremiumFeedCard(posts[index]),
                      childCount: posts.length,
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 3,
          padding: const EdgeInsets.only(top: 16),
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _ShimmerSkeleton(width: 44, height: 44, borderRadius: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ShimmerSkeleton(width: 120, height: 16),
                          SizedBox(height: 8),
                          _ShimmerSkeleton(width: 80, height: 12),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ShimmerSkeleton(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const _ShimmerSkeleton(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const _ShimmerSkeleton(width: 150, height: 16),
                  const SizedBox(height: 16),
                  const _ShimmerSkeleton(width: double.infinity, height: 200, borderRadius: 16),
                ],
              ),
            );
          },
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  context.tr(en: 'Could not load posts', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸à·Š à¶´à·–à¶»à¶«à¶º à¶šà·… à¶±à·œà·„à·à¶š', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®•à®³à¯ˆ à®à®±à¯à®± à®®à¯à®Ÿà®¿à®¯à®µà®¿à®²à¯à®²à¯ˆ'),
                  style: AppTextStyles.titleSmall,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(communityFeedProvider),
                  child: Text(context.tr(en: 'Retry', si: 'à¶±à·à·€à¶­ à¶‹à¶­à·Šà·ƒà·à·„ à¶šà¶»à¶±à·Šà¶±', ta: 'à®®à¯€à®£à¯à®Ÿà¯à®®à¯ à®®à¯à®¯à®±à¯à®šà®¿')),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create_post'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildUserAvatar(String? imagePath, String fallbackName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: imagePath != null && imagePath.isNotEmpty
            ? SmartImage(src: imagePath, fit: BoxFit.cover)
            : Center(
                child: Text(
                  fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : 'U',
                  style: TextStyle(color: AppColors.primary, fontSize: size * 0.45, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildPremiumFeedCard(CommunityPost post) {
    final authorName = post.author?.fullName ?? 'Independent Farmer';
    final district = post.author?.location ?? 'Sri Lanka';
    final avatarUrl = post.author?.imagePath;
    final timeAgoStr = timeago.format(post.createdAt, locale: 'en');

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Gap between posts like Facebook
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildUserAvatar(avatarUrl, authorName, 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      Row(
                        children: [
                          if (post.category.isNotEmpty) ...[
                            Text(post.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(' â€¢ ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                          Text('$timeAgoStr â€¢ $district', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: Colors.grey.shade500),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.userId == Supabase.instance.client.auth.currentUser?.id)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // We will navigate to a generic edit screen or just show an alert dialog.
                        // For simplicity, let's show an alert dialog to edit text.
                        _showEditPostDialog(post);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(context.tr(en: 'Delete Post', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸ à¶¸à¶šà¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆ à®¨à¯€à®•à¯à®•à¯')),
                            content: Text(context.tr(en: 'Are you sure you want to delete this post?', si: 'à¶¸à·™à¶¸ à¶´à·…à¶šà·’à¶»à·“à¶¸ à¶¸à¶šà¶±à·Šà¶± à¶…à·€à·à·Šâ€à¶º à¶¶à·€ à·€à·’à·à·Šà·€à·à·ƒà¶¯?', ta: 'à®‡à®¨à¯à®¤ à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆ à®¨à¯€à®•à¯à®• à®µà®¿à®°à¯à®®à¯à®ªà¯à®•à®¿à®±à¯€à®°à¯à®•à®³à®¾?')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr(en: 'Cancel', si: 'à¶…à·€à¶½à¶‚à¶œà·” à¶šà¶»à¶±à·Šà¶±', ta: 'à®°à®¤à¯à®¤à¯ à®šà¯†à®¯à¯'))),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true), 
                                child: Text(context.tr(en: 'Delete', si: 'à¶¸à¶šà¶±à·Šà¶±', ta: 'à®¨à¯€à®•à¯à®•à¯'), style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          final failText = context.tr(en: 'Post could not be deleted. Check your connection and try again.', si: 'පළ කිරීම මැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'இடுகையை நீக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
                          try {
                            await ref.read(communityFeedProvider.notifier).deletePost(post.id);
                          } catch (_) {
                            messenger.showSnackBar(SnackBar(content: Text(failText)));
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.black87), SizedBox(width: 8), Text(context.tr(en: 'Edit Post', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸ à·ƒà¶‚à·ƒà·Šà¶šà¶»à¶«à¶º', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆà®¤à¯ à®¤à®¿à®°à¯à®¤à¯à®¤à¯'))]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text(context.tr(en: 'Delete Post', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸ à¶¸à¶šà¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆ à®¨à¯€à®•à¯à®•à¯'), style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Post Content
          GestureDetector(
            onTap: () => context.push('/post_detail', extra: post),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.title != null && post.title!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(post.title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Edge-to-edge Image
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push('/post_detail', extra: post),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: SmartImage(src: post.imageUrl!, fit: BoxFit.cover),
                ),
              ),
            ),
          ],

          // Stats Row
          if (post.likesCount > 0 || post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (post.likesCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.thumb_up, color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.isLikedByMe 
                        ? (post.likesCount == 1 ? 'You' : 'You and ${post.likesCount - 1} others') 
                        : '${post.likesCount}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                    ),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    Text(
                      post.commentsCount == 1 ? '1 comment' : '${post.commentsCount} comments', 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                    ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 1),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildInteractionButton(
                  icon: post.isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: context.tr(en: 'Like', si: 'à¶šà·à¶¸à¶­à·’à¶ºà·’', ta: 'à®µà®¿à®°à¯à®ªà¯à®ªà®®à¯'),
                  color: post.isLikedByMe ? AppColors.primary : Colors.grey.shade700,
                  onTap: () => ref.read(communityFeedProvider.notifier).toggleLike(post.id),
                ),
              ),
              Expanded(
                child: _buildInteractionButton(
                  icon: Icons.chat_bubble_outline,
                  label: context.tr(en: 'Comment', si: 'à¶…à¶¯à·„à·ƒà·Š', ta: 'à®•à®°à¯à®¤à¯à®¤à¯'),
                  color: Colors.grey.shade700,
                  onTap: () => context.push('/post_detail', extra: post),
                ),
              ),
              Expanded(
                child: _buildInteractionButton(
                  icon: Icons.share_outlined,
                  label: context.tr(en: 'Share', si: 'à¶¶à·™à¶¯à·à¶œà¶±à·Šà¶±', ta: 'à®ªà®•à®¿à®°à¯'),
                  color: Colors.grey.shade700,
                  onTap: () => _sharePost(post),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDialog(CommunityPost post) {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(en: 'Edit Post', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸ à·ƒà¶‚à·ƒà·Šà¶šà¶»à¶«à¶º', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆà®¤à¯ à®¤à®¿à®°à¯à®¤à¯à®¤à¯'), style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              if (post.title != null) ...[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final failText = context.tr(en: 'Post could not be updated. Check your connection and try again.', si: 'පළ කිරීම යාවත්කාලීන කළ නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'இடுகையைப் புதுப்பிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
                    Navigator.pop(context);
                    try {
                      await ref.read(communityFeedProvider.notifier).editPost(
                        post.id,
                        contentController.text,
                        title: post.title != null ? titleController.text : null,
                        imageUrl: post.imageUrl,
                        category: post.category,
                      );
                    } catch (_) {
                      messenger.showSnackBar(SnackBar(content: Text(failText)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(context.tr(en: 'Save Changes', si: 'à·€à·™à¶±à·ƒà·Šà¶šà¶¸à·Š à·ƒà·”à¶»à¶šà·’à¶±à·Šà¶±', ta: 'à®®à®¾à®±à¯à®±à®™à¯à®•à®³à¯ˆà®šà¯ à®šà¯‡à®®à®¿'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

