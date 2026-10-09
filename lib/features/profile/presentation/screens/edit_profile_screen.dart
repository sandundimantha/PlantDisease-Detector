import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Image State
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false; // BUG-03 guard: prevent didChangeDependencies from overwriting edits

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _farmNameController;
  late TextEditingController _farmSizeController;
  late TextEditingController _bioController;

  // Dropdown state
  String _selectedDistrict = 'Colombo';
  final List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle'
  ];

  // Chips State
  final List<String> _availableCrops = ['Rice', 'Tomato', 'Chili', 'Coconut', 'Potato', 'Tea', 'Rubber', 'Cinnamon'];
  final List<String> _selectedCrops = ['Rice', 'Tomato'];

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized in didChangeDependencies
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _farmNameController = TextEditingController();
    _farmSizeController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return; // Guard: only initialize once
    _isInitialized = true;
    final userData = ref.read(userProvider);
    _nameController.text = userData.fullName;
    _phoneController.text = userData.phoneNumber;
    _emailController.text = userData.email;
    _farmNameController.text = userData.farmName;
    _farmSizeController.text = userData.farmSize;
    _bioController.text = userData.bio;
    if (userData.district.isNotEmpty && !_districts.contains(userData.district)) {
      _districts.insert(0, userData.district);
    }
    _selectedDistrict = _districts.contains(userData.district) ? userData.district : _districts.first;
    _selectedCrops.clear();
    _selectedCrops.addAll(userData.primaryCrops);
    if (userData.imagePath != null) {
      _imageFile = XFile(userData.imagePath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Close bottom sheet
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(context.tr(en: 'Update Profile Picture', si: 'පැතිකඩ පින්තූරය වෙනස් කරන්න', ta: 'சுயவிவரப் படத்தைப் புதுப்பி'), style: AppTextStyles.titleMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(icon: Icons.camera_alt_rounded, label: context.tr(en: 'Camera', si: 'කැමරාව', ta: 'கேமரா'), onTap: () => _pickImage(ImageSource.camera)),
                _buildPickerOption(icon: Icons.photo_library_rounded, label: context.tr(en: 'Gallery', si: 'ගැලරිය', ta: 'கேலரி'), onTap: () => _pickImage(ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Show loading overlay or something, but for simplicity just await
      
      String? finalImagePath = _imageFile?.path;
      if (finalImagePath != null && !finalImagePath.startsWith('http') && !finalImagePath.startsWith('data:image')) {
        try {
          final bytes = await _imageFile!.readAsBytes();
          final extension = finalImagePath.split('.').last.toLowerCase();
          final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
          final base64String = base64Encode(bytes);
          finalImagePath = 'data:$mimeType;base64,$base64String';
        } catch (e) {
          debugPrint('Error converting image to base64: $e');
        }
      }

      final updatedUser = UserData(
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        district: _selectedDistrict,
        farmName: _farmNameController.text,
        farmSize: _farmSizeController.text,
        bio: _bioController.text,
        primaryCrops: List.from(_selectedCrops),
        imagePath: finalImagePath,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final savedText = context.tr(en: 'Profile updated', si: 'පැතිකඩ යාවත්කාලීන කළා', ta: 'சுயவிவரம் புதுப்பிக்கப்பட்டது');
      final failText = context.tr(
        en: 'Could not save to your account. Check your connection and try again.',
        si: 'ඔබේ ගිණුමට සුරැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
        ta: 'உங்கள் கணக்கில் சேமிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
      );
      final saved = await ref.read(userProvider.notifier).saveUserData(updatedUser);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(saved ? savedText : failText),
        backgroundColor: saved ? AppColors.primary : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      if (saved) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Edit Profile', si: 'පැතිකඩ සංස්කරණය', ta: 'சுயவிவரத்தைத் திருத்து'), style: AppTextStyles.titleMedium),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerBottomSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          image: _getProfileImageProvider() != null 
                              ? DecorationImage(image: _getProfileImageProvider()!, fit: BoxFit.cover) 
                              : null,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: _getProfileImageProvider() == null
                            ? Center(
                                child: Text(
                                  _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 48, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Personal Info Section
              _buildSectionHeader('Personal Information', Icons.person_rounded),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildTextField(controller: _nameController, label: context.tr(en: 'Full Name', si: 'සම්පූර්ණ නම', ta: 'முழு பெயர்'), icon: Icons.badge_outlined),
                    const Divider(height: 1),
                    _buildTextField(controller: _phoneController, label: context.tr(en: 'Phone Number', si: 'දුරකථන අංකය', ta: 'தொலைபேசி எண்'), icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const Divider(height: 1),
                    _buildTextField(controller: _emailController, label: context.tr(en: 'Email Address', si: 'විද්‍යුත් තැපැල් ලිපිනය', ta: 'மின்னஞ்சல் முகவரி'), icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const Divider(height: 1),
                    _buildDropdownField(label: context.tr(en: 'District', si: 'දිස්ත්‍රික්කය', ta: 'மாவட்டம்'), icon: Icons.location_on_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Farm Details Section
              _buildSectionHeader('Farm Details', Icons.agriculture_rounded),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildTextField(controller: _farmNameController, label: context.tr(en: 'Farm Name', si: 'ගොවිපලේ නම', ta: 'பண்ணை பெயர்'), icon: Icons.landscape_outlined),
                    const Divider(height: 1),
                    _buildTextField(controller: _farmSizeController, label: context.tr(en: 'Farm Size (Acres)', si: 'ගොවිපලේ ප්‍රමාණය (අක්කර)', ta: 'பண்ணை அளவு (ஏக்கர்)'), icon: Icons.square_foot_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Crops Section
              Text(context.tr(en: 'Primary Crops', si: 'ප්‍රධාන බෝග', ta: 'முக்கிய பயிர்கள்'), style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _availableCrops.map((crop) {
                  final isSelected = _selectedCrops.contains(crop);
                  return FilterChip(
                    label: Text(crop),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCrops.add(crop);
                        } else {
                          _selectedCrops.remove(crop);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Bio Section
              _buildSectionHeader('Bio & Experience', Icons.info_outline_rounded),
              _buildCardContainer(
                child: _buildTextField(
                  controller: _bioController, 
                  label: context.tr(en: 'Tell us about your farming journey...', si: 'ඔබේ ගොවි ගමන ගැන අපට කියන්න...', ta: 'உங்கள் விவசாயப் பயணம் பற்றிச் சொல்லுங்கள்...'), 
                  icon: Icons.edit_note_rounded,
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(context.tr(en: 'Save Changes', si: 'වෙනස්කම් සුරකින්න', ta: 'மாற்றங்களைச் சேமி'), style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider() {
    if (_imageFile != null) {
      if (_imageFile!.path.startsWith('data:image')) {
        try {
          var base64String = _imageFile!.path.split(',').last.replaceAll(RegExp(r'\s+'), '');
          final padding = base64String.length % 4;
          if (padding != 0) {
            base64String += '=' * (4 - padding);
          }
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          debugPrint('Profile image base64 decode error: $e');
          return null;
        }
      } else if (_imageFile!.path.startsWith('http')) {
        return NetworkImage(_imageFile!.path);
      } else if (kIsWeb) {
        return NetworkImage(_imageFile!.path);
      } else {
        return FileImage(File(_imageFile!.path));
      }
    }
    return null;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade400, size: 22) : null,
          border: InputBorder.none,
          contentPadding: maxLines == 1 ? const EdgeInsets.symmetric(vertical: 16) : const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _districts.contains(_selectedDistrict) ? _selectedDistrict : (_districts.isNotEmpty ? _districts.first : null),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                items: _districts.map((String district) {
                  return DropdownMenuItem<String>(value: district, child: Text(district));
                }).toList(),
                onChanged: (String? val) {
                  if (val != null) setState(() => _selectedDistrict = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
