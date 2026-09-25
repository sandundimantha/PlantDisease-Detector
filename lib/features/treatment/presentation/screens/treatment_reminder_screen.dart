import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

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
  String _frequency = 'Every 7 Days';
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);

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
                        child: DropdownButton<String>(
                          value: _frequency,
                          isExpanded: true,
                          style: AppTextStyles.titleMedium,
                          items: ['Every Day', 'Every 3 Days', 'Every 7 Days', 'Every 14 Days'].map((String val) {
                            return DropdownMenuItem<String>(value: val, child: Text(val));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _frequency = val);
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr(en: 'Treatment reminder scheduled successfully!', si: 'ප්‍රතිකාර මතක් කිරීම සාර්ථකව සැකසිණි!', ta: 'சிகிச்சை நினைவூட்டல் வெற்றிகரமாக திட்டமிடப்பட்டது!')),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(context.tr(en: 'Save Reminder', si: 'මතක් කිරීම සුරකින්න', ta: 'நினைவூட்டலை சேமிக்கவும்'), style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
