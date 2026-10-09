import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedDistrict = 'Colombo';
  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 
    'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 
    'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala', 
    'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 
    'Trincomalee', 'Vavuniya'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(en: 'Please fill all fields', si: 'කරුණාකර සියලුම විස්තර පුරවන්න', ta: 'அனைத்து விவரங்களையும் நிரப்பவும்')), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'district': _selectedDistrict,
          // Stored on the new profile by handle_new_user() (migration 019).
          'preferred_lang': AppStrings.currentLocaleCode,
        },
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(en: 'Registration successful! Please check your email to confirm your account.', si: 'ලියාපදිංචිය සාර්ථකයි! ගිණුම තහවුරු කිරීමට ඔබේ විද්‍යුත් තැපෑල පරීක්ෂා කරන්න.', ta: 'பதிவு வெற்றிகரமானது! கணக்கை உறுதிப்படுத்த உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்.')),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
          // Don't navigate to main yet because they aren't authenticated.
          context.go('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(en: 'Account Created Successfully!', si: 'ගිණුම සාර්ථකව සෑදිණි!', ta: 'கணக்கு வெற்றிகரமாக உருவாக்கப்பட்டது!')), backgroundColor: Colors.green),
          );
          context.go('/main');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trAuthError(e.message)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1599839619722-39751411ea63?q=80&w=800&auto=format&fit=crop',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        AppColors.background,
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                      ),
                      const LanguageSelectorButton(isDark: true),
                    ],
                  ),
                ),
                // Form Container — sits at the bottom and scrolls when it is
                // taller than the space left (long translations, small screens).
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(
                        context.tr(en: 'Join Lumina', si: 'Lumina වෙත එක්වන්න', ta: 'Lumina இல் இணையுங்கள்'),
                        style: AppTextStyles.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          en: 'Complete your profile to get personalized advice.',
                          si: 'පුද්ගලාරෝපිත උපදෙස් ලබාගැනීමට ඔබගේ තොරතුරු සම්පූර්ණ කරන්න.',
                          ta: 'தனிப்பயனாக்கப்பட்ட ஆலோசனையைப் பெற உங்கள் சுயவிவரத்தை முடிக்கவும்.',
                        ),
                        style: AppTextStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Full Name Field
                      Text(context.tr(en: 'Full Name', si: 'සම්පූර්ණ නම', ta: 'முழு பெயர்'), style: AppTextStyles.titleSmall),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _nameController, hint: 'e.g. Sunil Perera', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      
                      // Email Field
                      Text(context.tr(en: 'Email', si: 'විද්‍යුත් තැපෑල', ta: 'மின்னஞ்சல்'), style: AppTextStyles.titleSmall),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _emailController, hint: 'e.g. sunil@example.com', icon: Icons.email_outlined),
                      const SizedBox(height: 16),

                      // Password Field
                      Text(context.tr(en: 'Password', si: 'මුරපදය', ta: 'கடவுச்சொல்'), style: AppTextStyles.titleSmall),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline_rounded, isPassword: true),
                      const SizedBox(height: 16),
                      
                      // District Dropdown
                      Text(context.tr(en: 'District', si: 'දිස්ත්‍රික්කය', ta: 'மாவட்டம்'), style: AppTextStyles.titleSmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            isExpanded: true,
                            style: AppTextStyles.titleMedium,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: _districts.map((String district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedDistrict = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              context.tr(en: 'Complete Registration', si: 'ලියාපදිංචිය සම්පූර්ණ කරන්න', ta: 'பதிவை முடிக்கவும்'),
                              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontSize: 16),
                            ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: AppTextStyles.titleMedium,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
          hintText: hint,
          hintStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

}

