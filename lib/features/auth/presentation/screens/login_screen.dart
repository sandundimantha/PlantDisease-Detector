import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/auth/user_role.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/main_screen.dart';

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

  // Forgot password: Supabase emails a reset link to the address entered.
  Future<void> _showForgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _emailController.text.trim()),
    );
    if (email == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      messenger.showSnackBar(SnackBar(
        content: Text(context.tr(en: 'Enter a valid email address', si: 'වලංගු විද්‍යුත් තැපැල් ලිපිනයක් ඇතුළත් කරන්න', ta: 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்')),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final sentText = context.tr(
      en: 'If an account exists for $email, a reset link has been sent. Check your inbox.',
      si: '$email සඳහා ගිණුමක් ඇත්නම් යළි සැකසීමේ සබැඳියක් යවා ඇත. ඔබේ තැපැල් පෙට්ටිය පරීක්ෂා කරන්න.',
      ta: '$email க்கு கணக்கு இருந்தால், மீட்டமைப்பு இணைப்பு அனுப்பப்பட்டது. உங்கள் இன்பாக்ஸைச் சரிபார்க்கவும்.',
    );
    final failText = context.tr(en: 'Could not send the email. Check your connection and try again.', si: 'විද්‍යුත් තැපෑල යැවිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'மின்னஞ்சலை அனுப்ப முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      messenger.showSnackBar(SnackBar(content: Text(sentText), backgroundColor: AppColors.primary, duration: const Duration(seconds: 5)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failText), backgroundColor: Colors.red));
    }
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(en: 'Please enter email and password', si: 'කරුණාකර විද්‍යුත් තැපෑල සහ මුරපදය ඇතුළත් කරන්න', ta: 'மின்னஞ்சல் மற்றும் கடவுச்சொல்லை உள்ளிடவும்')), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Route by the role stored in Supabase, not by the tab that was picked.
      final role = await fetchUserRole();
      final rejection = role == null
          ? 'Could not verify your account. Check your connection and try again.'
          : (_selectedRole == 'Officer' && role != 'officer')
              ? 'This account is not registered as an officer. Please log in as a Farmer.'
              : null;
      if (role == null || rejection != null) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(rejection!),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ref.read(mainTabProvider.notifier).state = 0; // always land on Home
        context.go(homeRouteForRole(role));
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

          // Top Right Language Selector
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: const LanguageSelectorButton(),
              ),
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
                              const SizedBox(width: 12),
                              // Flexible so long translations (e.g. Tamil) wrap instead of overflowing.
                              Flexible(
                                child: TextButton(
                                  onPressed: _showForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    context.tr(en: 'forgot password?', si: 'මුරපදය අමතකද?', ta: 'கடவுச்சொல் மறந்துவிட்டதா?'),
                                    textAlign: TextAlign.end,
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                                  ),
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

                          // Social login removed: those buttons opened the app without signing in.
                          // Sign up text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr(en: "Don't have an account? ", si: 'ගිණුමක් නැද්ද? ', ta: 'கணக்கு இல்லையா? '),
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.normal),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/signup'),
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
          role == 'Officer'
              ? context.tr(en: 'Officer', si: 'නිලධාරී', ta: 'அலுவலர்')
              : context.tr(en: 'Farmer', si: 'ගොවියා', ta: 'விவசாயி'),
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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


/// Asks for the email to send a password reset link to. Owns its text
/// controller so it is only disposed after the dialog has fully closed.
class _ResetPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ResetPasswordDialog({required this.initialEmail});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.tr(en: 'Reset your password', si: 'මුරපදය යළි සකසන්න', ta: 'கடவுச்சொல்லை மீட்டமைக்கவும்')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(
            en: 'Enter your email. We will send you a link to set a new password.',
            si: 'ඔබේ විද්‍යුත් තැපෑල ඇතුළත් කරන්න. නව මුරපදයක් සැකසීමට සබැඳියක් එවනු ලැබේ.',
            ta: 'உங்கள் மின்னஞ்சலை உள்ளிடவும். புதிய கடவுச்சொல்லை அமைக்க இணைப்பு அனுப்பப்படும்.',
          )),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'name@example.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr(en: 'Cancel', si: 'අවලංගු කරන්න', ta: 'ரத்து செய்')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(context.tr(en: 'Send link', si: 'සබැඳිය යවන්න', ta: 'இணைப்பை அனுப்பு'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
