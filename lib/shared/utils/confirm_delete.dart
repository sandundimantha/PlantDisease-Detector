import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

/// Asks before a permanent delete. Returns true when the user confirms.
Future<bool> confirmDelete(BuildContext context, {required String itemName}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.tr(en: 'Delete $itemName?', si: '$itemName මකන්නද?', ta: '$itemName நீக்கவா?')),
      content: Text(context.tr(
        en: 'This cannot be undone.',
        si: 'මෙය ආපසු හැරවිය නොහැක.',
        ta: 'இதை மீட்டெடுக்க முடியாது.',
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
  return ok == true;
}
