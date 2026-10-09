import 'package:flutter/material.dart';
import 'package:plant_disease_detector/shared/utils/confirm_delete.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/yield_tracker_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/add_farm_log_screen.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/features/farm_log/data/farm_models.dart';
import 'package:plant_disease_detector/features/farm_log/application/farm_provider.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/widgets/farm_forms.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FarmScreen — Matches Figma FarmScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class FarmScreen extends ConsumerStatefulWidget {
  const FarmScreen({super.key});

  @override
  ConsumerState<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends ConsumerState<FarmScreen> {
  String? _selectedFieldId;

  void _onScan() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraCaptureScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldBlocksProvider);
    final tasksAsync = ref.watch(farmTaskNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr(en: 'My Farm', si: 'මගේ ගොවිපල', ta: 'என் பண்ணை'),
                          style: AppTextStyles.headlineMedium.copyWith(letterSpacing: -0.5, fontSize: 24),
                        ),
                        const SizedBox(height: 2),
                        Builder(builder: (context) {
                          final fields = fieldsAsync.valueOrNull ?? const <FieldBlock>[];
                          final acres = fields.fold<double>(0, (sum, f) => sum + fieldAcres(f));
                          final a = acres % 1 == 0 ? acres.toInt().toString() : acres.toStringAsFixed(1);
                          return Text(
                            fields.isEmpty
                                ? context.tr(en: 'No fields added yet', si: 'තවම ක්ෂේත්‍ර එක් කර නැත', ta: 'இன்னும் வயல்கள் சேர்க்கப்படவில்லை')
                                : context.tr(
                                    en: '$a total acres · ${fields.length} ${fields.length == 1 ? 'field' : 'fields'}',
                                    si: 'අක්කර $a · ක්ෂේත්‍ර ${fields.length}',
                                    ta: '$a மொத்த ஏக்கர் · ${fields.length} வயல்கள்',
                                  ),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.settingsIcon),
                          );
                        }),
                      ],
                    ),
                  ),
                  const LanguageSelectorButton(isCompact: true),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _onScan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.profileCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppColors.severityHigh.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Text(
                        context.tr(en: '+ Scan Field', si: '+ ක්ෂේත්‍රය ස්කෑන්', ta: '+ பயிர் ஸ்கேன்'),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Health
                    _buildOverallHealth(),
                    const SizedBox(height: 20),

                    // Field Blocks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(en: 'Field Blocks', si: 'ක්ෂේත්‍ර කොටස්', ta: 'பண்ணை தொகுதிகள்'),
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                        ),
                        _smallAction(
                          context.tr(en: 'Add Field', si: 'ක්ෂේත්‍රය එක්කරන්න', ta: 'வயல் சேர்க்க'),
                          () => showAddFieldSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    fieldsAsync.when(
                      data: (fields) => fields.isEmpty
                          ? _emptyCard(
                              Icons.grid_view_rounded,
                              context.tr(
                                en: 'Add your fields to track their health and harvests.',
                                si: 'ඒවායේ සෞඛ්‍යය සහ අස්වැන්න සොයා බැලීමට ඔබේ ක්ෂේත්‍ර එක් කරන්න.',
                                ta: 'அவற்றின் ஆரோக்கியத்தையும் அறுவடையையும் கண்காணிக்க உங்கள் வயல்களைச் சேர்க்கவும்.',
                              ),
                            )
                          : Column(
                              children: fields.map((f) => _buildFieldCard(f)).toList(),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading fields: $err'),
                    ),

                    const SizedBox(height: 20),

                    // Tasks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(en: "Today's Tasks", si: 'අද දවසේ කාර්යයන්', ta: 'இன்றைய பணிகள்'),
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddFarmLogScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr(en: 'Add Log', si: 'සටහනක් එක්කරන්න', ta: 'பதிவு சேர்க்க'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    tasksAsync.when(
                      data: (tasks) => tasks.isEmpty
                          ? _emptyCard(
                              Icons.event_note_rounded,
                              context.tr(
                                en: 'No tasks yet. Tap Add Log to record watering, spraying or harvesting.',
                                si: 'තවම කාර්යයන් නැත. ජලය දැමීම, ඉසීම හෝ අස්වනු නෙළීම සටහන් කිරීමට සටහනක් එක්කරන්න ඔබන්න.',
                                ta: 'இன்னும் பணிகள் இல்லை. நீர்ப்பாசனம், தெளிப்பு அல்லது அறுவடையைப் பதிவுசெய்ய பதிவு சேர்க்க என்பதைத் தட்டவும்.',
                              ),
                            )
                          : Column(
                              children: tasks.map((t) => _buildTaskCard(t)).toList(),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading tasks: $err'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAction(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildOverallHealth() {
    // Real numbers from the farmer's field blocks (average health score and
    // how many blocks are Healthy / Monitor / At Risk).
    final fields = ref.watch(fieldBlocksProvider).valueOrNull ?? const <FieldBlock>[];
    final avg = fields.isEmpty ? 0 : (fields.map((f) => f.healthScore).reduce((a, b) => a + b) / fields.length).round().clamp(0, 100);
    int count(String status) => fields.where((f) => f.status.toLowerCase() == status).length;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const YieldTrackerScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr(
                        en: 'Overall Farm Health & Yield',
                        si: 'ගොවිපල සමස්ත සෞඛ්‍යය හා අස්වැන්න',
                        ta: 'ஒட்டுமொத்த பண்ணை நலம் & விளைச்சல்',
                      ),
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                  ],
                ),
                Text(fields.isEmpty ? '—' : '$avg%', style: AppTextStyles.titleSmall.copyWith(color: AppColors.severityDefault, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: avg.toInt(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.healthBarLight, AppColors.severityDefault]),
                        ),
                      ),
                    ),
                    Expanded(flex: 100 - avg.toInt(), child: Container(color: AppColors.imageLoadingBg)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHealthStat(context.tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியமானது'), '${count('healthy')}', AppColors.severityDefault),
                _buildHealthStat(context.tr(en: 'Monitor', si: 'නිරීක්ෂණය', ta: 'கண்காணிப்பு'), '${count('monitor')}', AppColors.severityMedium),
                _buildHealthStat(context.tr(en: 'At Risk', si: 'අවදානමේ', ta: 'ஆபத்தில்'), '${count('at risk')}', AppColors.severityHigh),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStat(String label, String val, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains("risk")) return AppColors.severityHigh;
    if (s.contains("healthy")) return AppColors.severityDefault;
    return AppColors.severityMedium;
  }

  Widget _buildFieldCard(FieldBlock field) {
    final isExpanded = _selectedFieldId == field.id;
    final statusColor = _getStatusColor(field.status);

    return Dismissible(
      key: Key(field.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.severityHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => confirmDelete(context, itemName: field.name),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final deleted = context.tr(en: 'Field block deleted', si: 'ක්ෂේත්‍ර කොටස මකා දැමිණි', ta: 'நிலத் தொகுதி நீக்கப்பட்டது');
        final failed = context.tr(en: 'Could not delete. Check your connection and try again.', si: 'මැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'நீக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
        try {
          await ref.read(farmApiServiceProvider).deleteFieldBlock(field.id);
          messenger.showSnackBar(SnackBar(content: Text(deleted)));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(failed), backgroundColor: Colors.red));
        }
        ref.invalidate(fieldBlocksProvider);
      },
      child: GestureDetector(
      onTap: () => setState(() => _selectedFieldId = isExpanded ? null : field.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      SmartImage(
                        src: field.imageUrl ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          field.name.isNotEmpty ? field.name.split(' ').last.toUpperCase() : '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(field.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleSmall.copyWith(fontSize: 14)),
                                  Text('${field.crop} · ${field.area}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                              child: Text(
                                switch (field.status.toLowerCase()) {
                                  'healthy' => context.tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியம்'),
                                  'monitor' => context.tr(en: 'Monitor', si: 'නිරීක්ෂණය', ta: 'கண்காணி'),
                                  'at risk' => context.tr(en: 'At Risk', si: 'අවදානමේ', ta: 'ஆபத்து'),
                                  _ => field.status,
                                },
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: SizedBox(
                                  height: 5,
                                  child: Row(
                                    children: [
                                      Expanded(flex: field.healthScore, child: Container(color: statusColor)),
                                      Expanded(flex: 100 - field.healthScore, child: Container(color: AppColors.imageLoadingBg)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${field.healthScore}%', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.dividerSubtle)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildFieldDetail('Last Scan', '2 days ago')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildFieldDetail('Next Water', 'Tomorrow')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildFieldDetail('Rows', '18 rows')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _onScan,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppGradients.profileCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Scan ${field.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFieldDetail(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.achievementInactive, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(val, style: AppTextStyles.titleSmall.copyWith(fontSize: 12)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getTaskColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return AppColors.severityHigh;
    if (p == 'done') return AppColors.severityDefault;
    if (p == 'low') return AppColors.severityLow;
    return AppColors.severityMedium;
  }

  Widget _buildTaskCard(FarmTask task) {
    final color = _getTaskColor(task.priority);
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.severityHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final deleted = context.tr(en: 'Task deleted', si: 'කාර්යය මකා දැමිණි', ta: 'பணி நீக்கப்பட்டது');
        final failed = context.tr(en: 'Could not delete. Check your connection and try again.', si: 'මැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'நீக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.');
        try {
          await ref.read(farmApiServiceProvider).deleteFarmTask(task.id);
          messenger.showSnackBar(SnackBar(content: Text(deleted)));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(failed), backgroundColor: Colors.red));
        }
        ref.read(farmTaskNotifierProvider.notifier).refresh();
      },
      child: GestureDetector(
      onTap: () {
        ref.read(farmTaskNotifierProvider.notifier).toggleTask(task.id, !task.isDone);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Opacity(
          opacity: task.isDone ? 0.6 : 1.0,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.isDone ? AppColors.severityDefault : color.withValues(alpha: 0.1),
                  border: task.isDone ? null : Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: task.isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    Text(task.dueDate, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  task.isDone ? "Done" : task.priority,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
