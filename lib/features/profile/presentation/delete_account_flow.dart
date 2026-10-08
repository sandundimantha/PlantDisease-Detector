import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';

/// Delete Account — confirm, then remove the account in Supabase, sign out and
/// go to Login. Used from Profile and from Settings.
Future<void> confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.tr(en: 'Delete your account?', si: 'ඔබේ ගිණුම මකන්නද?', ta: 'உங்கள் கணக்கை நீக்கவா?')),
      content: Text(context.tr(
        en: 'Your profile, scans, saved items, farm logs and consultations will be permanently deleted. This cannot be undone.',
        si: 'ඔබේ පැතිකඩ, ස්කෑන්, සුරැකි අයිතම, ගොවි සටහන් සහ උපදේශන සදහටම මැකී යයි. මෙය ආපසු හැරවිය නොහැක.',
        ta: 'உங்கள் சுயவிவரம், ஸ்கேன்கள், சேமித்தவை, பண்ணைப் பதிவுகள் மற்றும் ஆலோசனைகள் நிரந்தரமாக நீக்கப்படும். இதை மீட்டெடுக்க முடியாது.',
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr(en: 'Cancel', si: 'අවලංගු කරන්න', ta: 'ரத்து செய்')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            context.tr(en: 'Delete', si: 'මකන්න', ta: 'நீக்கு'),
            style: const TextStyle(color: AppColors.signOutText, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final deletedText = context.tr(en: 'Your account has been deleted', si: 'ඔබේ ගිණුම මකා දමන ලදී', ta: 'உங்கள் கணக்கு நீக்கப்பட்டது');
  final failedText = context.tr(
    en: 'Could not delete the account. Check your internet connection and try again.',
    si: 'ගිණුම මැකිය නොහැක. අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
    ta: 'கணக்கை நீக்க முடியவில்லை. இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  );
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
  try {
    await ref.read(userProvider.notifier).deleteMyAccount();
    rootNavigator.pop();
    router.go('/login');
    messenger.showSnackBar(SnackBar(content: Text(deletedText), backgroundColor: AppColors.primary));
  } catch (e) {
    rootNavigator.pop();
    final message = e is PostgrestException ? e.message : failedText;
    messenger.showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}
