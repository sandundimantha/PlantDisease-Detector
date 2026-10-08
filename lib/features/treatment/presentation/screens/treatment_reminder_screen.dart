import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/services/notification_service.dart';
import 'package:plant_disease_detector/core/providers/app_settings_provider.dart';

class TreatmentReminderScreen extends StatefulWidget {
  final String treatmentTitle;
  final String diseaseName;

  const TreatmentReminderScreen({
    super.key,
    this.treatmentTitle = 'Copper Fungicide Spray',
    this.diseaseName = 'Early Blight (Tomato)',
  });

  @override
  State<TreatmentReminderScreen> createState() => _TreatmentReminderScreenState();
}

class _TreatmentReminderScreenState extends State<TreatmentReminderScreen> {
  int _everyDays = 7;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  bool _saving = false;

  String _frequencyLabel(BuildContext context, int days) => days == 1
      ? context.tr(en: 'Every Day', si: 'සෑම දිනකම', ta: 'தினமும்')
      : context.tr(en: 'Every $days Days', si: 'දින $days කට වරක්', ta: '$days நாட்களுக்கு ஒருமுறை');

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final disease = context.trDisease(widget.diseaseName);
    final title = context.tr(en: 'Treatment reminder', si: 'ප්‍රතිකාර මතක් කිරීම', ta: 'சிகிச்சை நினைவூட்டல்');
    final body = '${widget.treatmentTitle} — $disease';
    final doneText = context.tr(en: 'Reminder set', si: 'මතක් කිරීම සකසා ඇත', ta: 'நினைவூட்டல் அமைக்கப்பட்டது');
    final offText = context.tr(
      en: 'Notifications are off. Turn them on in Settings to receive reminders.',
      si: 'දැනුම්දීම් අක්‍රියයි. මතක් කිරීම් ලැබීමට සැකසීම් තුළ ඒවා සක්‍රිය කරන්න.',
      ta: 'அறிவிப்புகள் முடக்கப்பட்டுள்ளன. நினைவூட்டல்களைப் பெற அமைப்புகளில் இயக்கவும்.',
    );
    final failText = context.tr(en: 'Could not set the reminder. Please try again.', si: 'මතක් කිරීම සැකසිය නොහැක. නැවත උත්සාහ කරන්න.', ta: 'நினைவூட்டலை அமைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.');
    final timeText = _time.format(context);

    setState(() => _saving = true);
    try {
      final first = await NotificationService().scheduleTreatmentReminders(
        title: title,
        body: body,
        everyDays: _everyDays,
        time: _time,
      );
      final day = '${first.day}/${first.month}';
      messenger.showSnackBar(SnackBar(
        content: Text(AppSettings.current.notifications ? '$doneText: $day, $timeText' : offText),
        backgroundColor: AppSettings.current.notifications ? AppColors.primary : AppColors.severityMedium,
      ));
      navigator.pop();
    } catch (e) {
      debugPrint('Reminder scheduling failed: $e');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(failText), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.tr(en: 'Schedule Reminder', si: 'මතක් කිරීමක් සකසන්න', ta: 'நினைவூட்டலை திட்டமிடுங்கள்'), style: AppTextStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          LanguageSelectorButton(isCompact: true),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medication_liquid_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.treatmentTitle, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                Text('${context.tr(en: 'For', si: 'සඳහා', ta: 'க்காக')}: ${context.trDisease(widget.diseaseName)}', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(context.tr(en: 'Frequency', si: 'වාර ගණන', ta: 'அதிர்வெண்'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _everyDays,
                          isExpanded: true,
                          style: AppTextStyles.titleMedium,
                          items: [1, 3, 7, 14].map((int days) {
                            return DropdownMenuItem<int>(value: days, child: Text(_frequencyLabel(context, days)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _everyDays = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(context.tr(en: 'Time of Day', si: 'දිනයේ වේලාව', ta: 'நேரம்'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_time.format(context), style: AppTextStyles.titleMedium),
                            const Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(context.tr(en: 'Save Reminder', si: 'මතක් කිරීම සුරකින්න', ta: 'நினைவூட்டலை சேமிக்கவும்'), style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
