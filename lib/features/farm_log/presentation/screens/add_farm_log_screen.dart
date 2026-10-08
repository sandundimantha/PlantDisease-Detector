import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:plant_disease_detector/features/farm_log/application/farm_provider.dart';

class AddFarmLogScreen extends ConsumerStatefulWidget {
  const AddFarmLogScreen({super.key});

  @override
  ConsumerState<AddFarmLogScreen> createState() => _AddFarmLogScreenState();
}

class _AddFarmLogScreenState extends ConsumerState<AddFarmLogScreen> {
  String _selectedActivity = 'Watering';
  DateTime _date = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final n = DateTime.now();
    return _date.year == n.year && _date.month == n.month && _date.day == n.day;
  }

  String _dateLabel(BuildContext context) {
    final d = DateFormat('d MMM yyyy').format(_date);
    return _isToday ? '${context.tr(en: 'Today', si: 'අද', ta: 'இன்று')}, $d' : d;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final savedText = context.tr(en: 'Farm log saved', si: 'ගොවි සටහන සුරැකිණි', ta: 'பண்ணைப் பதிவு சேமிக்கப்பட்டது');
    final failText = context.tr(en: 'Could not save. Check your connection and try again.', si: 'සුරැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'சேமிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
    final note = _notesController.text.trim();
    final data = {
      // The farm_tasks table has no notes column, so the note goes with the label.
      'label': note.isEmpty ? _selectedActivity : '$_selectedActivity — $note',
      'due_date': _isToday ? 'Today' : DateFormat('d MMM yyyy').format(_date),
      'priority': _selectedActivity == 'Spraying' ? 'High' : 'Medium',
      'is_done': false,
    };
    setState(() => _saving = true);
    try {
      await ref.read(farmApiServiceProvider).createFarmTask(data);
      ref.read(farmTaskNotifierProvider.notifier).refresh();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(savedText), backgroundColor: AppColors.primary));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(failText), backgroundColor: Colors.red));
    }
  }
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Watering', 'icon': Icons.water_drop_outlined, 'color': Colors.blue},
    {'name': 'Fertilizer', 'icon': Icons.eco_outlined, 'color': Colors.green},
    {'name': 'Spraying', 'icon': Icons.pest_control_outlined, 'color': AppColors.primary},
    {'name': 'Harvesting', 'icon': Icons.shopping_basket_outlined, 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.tr(en: 'New Farm Log', si: 'නව ගොවිපල සටහන', ta: 'புதிய பண்ணை பதிவு'), style: AppTextStyles.titleMedium),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr(en: 'Select Activity', si: 'ක්‍රියාකාරකම තෝරන්න', ta: 'செயல்பாட்டைத் தேர்ந்தெடுக்கவும்'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final act = _activities[index];
                        final isSelected = _selectedActivity == act['name'];
                        final actLabel = switch (act['name'] as String) {
                          'Watering' => context.tr(en: 'Watering', si: 'ජලය දැමීම', ta: 'நீர்ப்பாசனம்'),
                          'Fertilizer' => context.tr(en: 'Fertilizer', si: 'පොහොර යෙදීම', ta: 'உரமிடுதல்'),
                          'Spraying' => context.tr(en: 'Spraying', si: 'බෙහෙත් ඉසීම', ta: 'தெளித்தல்'),
                          'Harvesting' => context.tr(en: 'Harvesting', si: 'අස්වනු නෙලීම', ta: 'அறுவடை'),
                          _ => act['name'] as String,
                        };

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedActivity = act['name'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? (act['color'] as Color).withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? act['color'] as Color : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected ? [] : [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(act['icon'] as IconData, color: isSelected ? act['color'] as Color : AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(
                                  actLabel,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: isSelected ? act['color'] as Color : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Text(context.tr(en: 'Date', si: 'දිනය', ta: 'தேதி'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateLabel(context), style: AppTextStyles.titleMedium),
                            const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(context.tr(en: 'Notes (Optional)', si: 'සටහන් (අවශ්‍ය නම්)', ta: 'குறிப்புகள் (விருப்பமானது)'), style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: context.tr(en: 'e.g. Used NPK 15-15-15 on plot A', si: 'උදා: A කොටසට NPK 15-15-15 යෙදුවා', ta: 'எ.கா: A பகுதியில் NPK 15-15-15 இட்டேன்'),
                          hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
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
                    : Text(context.tr(en: 'Save Log Entry', si: 'සටහන සුරකින්න', ta: 'பதிவைச் சேமிக்கவும்'), style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
