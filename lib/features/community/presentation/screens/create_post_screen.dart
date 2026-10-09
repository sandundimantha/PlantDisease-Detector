import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:plant_disease_detector/features/community/application/community_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isLoading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['General', 'Trending', 'My Crops', 'Q&A'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 70, 
        maxWidth: 1024, 
        maxHeight: 1024
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(en: 'Please add some text or a photo to post.', si: 'à¶´à·… à¶šà·’à¶»à·“à¶¸à¶§ à¶´à·™à·…à¶šà·Š à·„à· à¶¡à·à¶ºà·à¶»à·–à¶´à¶ºà¶šà·Š à¶‘à¶šà·Š à¶šà¶»à¶±à·Šà¶±.', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à®¿à®Ÿ à®‰à®°à¯ˆ à®…à®²à¯à®²à®¤à¯ à®ªà®Ÿà®¤à¯à®¤à¯ˆà®šà¯ à®šà¯‡à®°à¯à®•à¯à®•à®µà¯à®®à¯.'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        // Determine mime type from extension
        final extension = _selectedImage!.name.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        base64Image = 'data:$mimeType;base64,$base64String';
      }

      await ref.read(communityFeedProvider.notifier).createPost(
        _contentController.text.trim(),
        title: null, // Removed title to make it more like Facebook
        imageUrl: base64Image,
        category: _selectedCategory,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final posted = context.tr(en: 'Post shared with the community', si: 'à¶´à·…à¶šà·’à¶»à·“à¶¸ à¶´à·Šâ€à¶»à¶¢à·à·€ à·ƒà¶¸à¶Ÿ à¶¶à·™à¶¯à·à¶œà¶±à·Šà¶±à· à¶½à¶¯à·“', ta: 'à®‡à®Ÿà¯à®•à¯ˆ à®šà®®à¯‚à®•à®¤à¯à®¤à¯à®Ÿà®©à¯ à®ªà®•à®¿à®°à®ªà¯à®ªà®Ÿà¯à®Ÿà®¤à¯');
        context.pop();
        messenger.showSnackBar(SnackBar(content: Text(posted), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(en: 'Could not post. Check your connection and try again.', si: 'à¶´à·… à¶šà·… à¶±à·œà·„à·à¶š. à·ƒà¶¸à·Šà¶¶à¶±à·Šà¶°à¶­à·à·€à¶º à¶´à¶»à·“à¶šà·Šà·‚à· à¶šà¶» à¶±à·à·€à¶­ à¶‹à¶­à·Šà·ƒà·à·„ à¶šà¶»à¶±à·Šà¶±.', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à®¿à®Ÿ à®®à¯à®Ÿà®¿à®¯à®µà®¿à®²à¯à®²à¯ˆ. à®‡à®£à¯ˆà®ªà¯à®ªà¯ˆà®šà¯ à®šà®°à®¿à®ªà®¾à®°à¯à®¤à¯à®¤à¯ à®®à¯€à®£à¯à®Ÿà¯à®®à¯ à®®à¯à®¯à®±à¯à®šà®¿à®•à¯à®•à®µà¯à®®à¯.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);
    final String displayName = userData.fullName.isNotEmpty ? userData.fullName : 'Farmer';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Create Post', si: 'à¶´à·… à¶šà¶»à¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆà®¯à¯ˆ à®‰à®°à¯à®µà®¾à®•à¯à®•à¯')),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: _submitPost,
                    style: TextButton.styleFrom(
                      backgroundColor: (_contentController.text.isNotEmpty || _selectedImage != null)
                          ? AppColors.primary
                          : Colors.grey.shade200,
                      foregroundColor: (_contentController.text.isNotEmpty || _selectedImage != null)
                          ? Colors.white
                          : Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(context.tr(en: 'Post', si: 'à¶´à·… à¶šà¶»à¶±à·Šà¶±', ta: 'à®‡à®Ÿà¯à®•à¯ˆ'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info & Category
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: userData.imagePath != null && userData.imagePath!.isNotEmpty
                              ? SmartImage(src: userData.imagePath!, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: AppTextStyles.titleSmall.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            // Modern compact category selector
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                                  isDense: true,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content Input
                  TextField(
                    controller: _contentController,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 20, height: 1.4),
                    maxLines: null, // Auto-expand
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'What\'s happening with your crops?',
                      hintStyle: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade400, fontSize: 20),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() {}),
                  ),

                  const SizedBox(height: 16),
                  
                  // Selected Image Preview
                  if (_selectedImage != null)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions ToolBar (Facebook Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Text(context.tr(en: 'Add to your post', si: 'à¶”à¶¶à·š à¶´à·…à¶šà·’à¶»à·“à¶¸à¶§ à¶‘à¶šà·Š à¶šà¶»à¶±à·Šà¶±', ta: 'à®‰à®™à¯à®•à®³à¯ à®‡à®Ÿà¯à®•à¯ˆà®¯à®¿à®²à¯ à®šà¯‡à®°à¯à®•à¯à®•à®µà¯à®®à¯'), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _buildToolIcon(
                    icon: Icons.photo_library_rounded,
                    color: Colors.green,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 16),
                  _buildToolIcon(
                    icon: Icons.camera_alt_rounded,
                    color: Colors.blue,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

