import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:plant_disease_detector/features/community/application/community_provider.dart';
import 'package:plant_disease_detector/features/community/data/community_models.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends ConsumerStatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(postCommentsProvider(widget.post.id).notifier).addComment(_commentController.text.trim());
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    final authorName = widget.post.author?.fullName ?? 'Farmer';
    final avatarUrl = widget.post.author?.imagePath;
    final timeAgoStr = timeago.format(widget.post.createdAt, locale: 'en_short');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(title: Text(context.tr(en: 'Post Details', si: 'පළකිරීමේ විස්තර', ta: 'இடுகை விவரங்கள்'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Post Content
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                      clipBehavior: Clip.antiAlias,
                      child: avatarUrl != null
                          ? SmartImage(src: avatarUrl, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authorName, style: AppTextStyles.titleMedium),
                        Text(timeAgoStr, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.post.title != null && widget.post.title!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(widget.post.title!, style: AppTextStyles.titleMedium.copyWith(fontSize: 22)),
                  ),
                Text(widget.post.content, style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
                if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SmartImage(
                      src: widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(context.tr(en: 'Comments', si: 'අදහස්', ta: 'கருத்துகள்'), style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),

                // Comments List
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(context.tr(en: 'No comments yet. Be the first to comment!', si: 'තවම අදහස් නැත. පළමුව අදහස් දක්වන්න!', ta: 'இன்னும் கருத்துகள் இல்லை. முதலில் கருத்துத் தெரிவியுங்கள்!'), style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, _i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final cAuthor = comment.author?.fullName ?? 'Farmer';
                        final cAvatar = comment.author?.imagePath;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                              clipBehavior: Clip.antiAlias,
                              child: cAvatar != null ? SmartImage(src: cAvatar, fit: BoxFit.cover) : const Icon(Icons.person, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(cAuthor, style: AppTextStyles.titleSmall),
                                        Text(timeago.format(comment.createdAt, locale: 'en_short'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(comment.content, style: AppTextStyles.bodyMedium),
                                  ],
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
          
          // Add Comment Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: context.tr(en: 'Add a comment...', si: 'අදහසක් එක් කරන්න...', ta: 'கருத்தைச் சேர்க்கவும்...'),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
