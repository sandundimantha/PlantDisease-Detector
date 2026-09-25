import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Farmer'; // Farmer or Officer

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1)); 
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (_selectedRole == 'Officer') {
        context.go('/officer_dashboard');
      } else {
        context.go('/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background blobs for glassmorphism effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
          ),
          
          // Glass effect overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header text
                    Text(
                      context.tr(en: 'LOGIN / SIGNUP', si: 'ඇතුල්වීම / ලියාපදිංචිය', ta: 'உள்நுழைவு / பதிவு'),
                      style: AppTextStyles.headlineLarge.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Glass Form Container
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role Selection Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildRoleButton('Farmer')),
                                Expanded(child: _buildRoleButton('Officer')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email label
                          Text(context.tr(en: 'Email', si: 'විද්‍යුත් තැපෑල', ta: 'மின்னஞ்சல்'), style: AppTextStyles.titleSmall),
                          const SizedBox(height: 8),
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            hint: context.tr(en: 'Enter your email', si: 'ඔබගේ විද්‍යුත් තැපෑල ඇතුළත් කරන්න', ta: 'உங்கள் மின்னஞ்சலை உள்ளிடவும்'),
                            icon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 20),

                          // Password label & forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr(en: 'Password', si: 'මුරපදය', ta: 'கடவுச்சொல்'), style: AppTextStyles.titleSmall),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.tr(en: 'forgot password?', si: 'මුරපදය අමතකද?', ta: 'கடவுச்சொல் மறந்துவிட்டதா?'),
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            hint: context.tr(en: 'Enter your password', si: 'ඔබගේ මුරපදය ඇතුළත් කරන්න', ta: 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்'),
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppGradients.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : Text(
                                      _selectedRole == 'Officer' 
                                          ? context.tr(en: 'LOGIN AS OFFICER', si: 'නිලධාරී ලෙස ඇතුල් වන්න', ta: 'அதிகாரியாக உள்நுழையவும்')
                                          : context.tr(en: 'LOGIN', si: 'ඇතුල් වන්න', ta: 'உள்நுழைக'),
                                      style: AppTextStyles.titleMedium.copyWith(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: AppColors.textPrimary.withValues(alpha: 0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(context.tr(en: 'OR', si: 'හෝ', ta: 'அல்லது'), style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6))),
                              ),
                              Expanded(child: Container(height: 1, color: AppColors.textPrimary.withValues(alpha: 0.2))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Login Label
                          Text(
                            context.tr(en: 'Social Login', si: 'සමාජ මාධ්‍ය හරහා ඇතුල් වන්න', ta: 'சமூக ஊடக உள்நுழைவு'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20),

                          // Social Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialCircle(Icons.facebook_rounded, AppColors.facebook, () => context.go('/main')),
                              const SizedBox(width: 24),
                              _buildSocialCircle(Icons.g_mobiledata_rounded, Colors.red, () => context.go('/main'), iconSize: 44),
                              const SizedBox(width: 24),
                              _buildSocialCircle(Icons.apple_rounded, Colors.black, () => context.go('/main')),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Sign up text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr(en: "Don't have an account? ", si: 'ගිණුමක් නැද්ද? ', ta: 'கணக்கு இல்லையா? '),
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.normal),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: Text(
                                  context.tr(en: 'Sign Up', si: 'ලියාපදිංචි වන්න', ta: 'பதிவு செய்க'),
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          role,
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCircle(IconData icon, Color color, VoidCallback onTap, {double iconSize = 28}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.6)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
