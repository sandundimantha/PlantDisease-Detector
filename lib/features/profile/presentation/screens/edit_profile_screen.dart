import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _farmNameController;
  late TextEditingController _farmSizeController;
  late TextEditingController _bioController;

  // Dropdown state
  String _selectedDistrict = 'Colombo';
  final List<String> _districts = ['Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya', 'Anuradhapura'];

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
    final userData = ref.read(userProvider);
    _nameController.text = userData.fullName;
    _phoneController.text = userData.phoneNumber;
    _emailController.text = userData.email;
    _farmNameController.text = userData.farmName;
    _farmSizeController.text = userData.farmSize;
    _bioController.text = userData.bio;
    _selectedDistrict = userData.district;
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
            Text('Update Profile Picture', style: AppTextStyles.titleMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () => _pickImage(ImageSource.camera)),
                _buildPickerOption(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery)),
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
      if (finalImagePath != null && !finalImagePath.startsWith('http')) {
        // It's a local file, upload to Supabase
        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;
          if (user != null) {
            final fileExt = finalImagePath.split('.').last;
            final fileName = '${user.id}_avatar.${fileExt}';
            
            // For web support, we need bytes.
            if (kIsWeb) {
               final bytes = await _imageFile!.readAsBytes();
               await client.storage.from('avatars').uploadBinary(
                 fileName, 
                 bytes, 
                 fileOptions: const FileOptions(upsert: true)
               );
               finalImagePath = client.storage.from('avatars').getPublicUrl(fileName);
            } else {
               await client.storage.from('avatars').upload(
                 fileName, 
                 File(finalImagePath), 
                 fileOptions: const FileOptions(upsert: true)
               );
               finalImagePath = client.storage.from('avatars').getPublicUrl(fileName);
            }
          }
        } catch (e) {
          debugPrint('Error uploading image: $e');
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

      await ref.read(userProvider.notifier).saveUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                          color: Colors.grey.shade200,
                          image: _buildProfileImage(),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
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
                    _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.badge_outlined),
                    const Divider(height: 1),
                    _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const Divider(height: 1),
                    _buildTextField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const Divider(height: 1),
                    _buildDropdownField(label: 'District', icon: Icons.location_on_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Farm Details Section
              _buildSectionHeader('Farm Details', Icons.agriculture_rounded),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildTextField(controller: _farmNameController, label: 'Farm Name', icon: Icons.landscape_outlined),
                    const Divider(height: 1),
                    _buildTextField(controller: _farmSizeController, label: 'Farm Size (Acres)', icon: Icons.square_foot_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Crops Section
              Text('Primary Crops', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary)),
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
                  label: 'Tell us about your farming journey...', 
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
                  child: Text('Save Changes', style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _buildProfileImage() {
    if (_imageFile != null) {
      if (_imageFile!.path.startsWith('http')) {
        return DecorationImage(image: NetworkImage(_imageFile!.path), fit: BoxFit.cover);
      } else if (kIsWeb) {
        return DecorationImage(image: NetworkImage(_imageFile!.path), fit: BoxFit.cover);
      } else {
        return DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover);
      }
    }
    // Default mock image
    return const DecorationImage(
      image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop'),
      fit: BoxFit.cover,
    );
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
                value: _selectedDistrict,
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
