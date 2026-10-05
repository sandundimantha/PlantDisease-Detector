import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/features/officer/data/visit_repository.dart';
import 'package:plant_disease_detector/models/consultation.dart';
import 'package:plant_disease_detector/models/officer_visit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _teal = Color(0xFF0F766E);
const _terracotta = Color(0xFFD9734E);

// ─────────────────────────────────────────────────────────────────────────────
// ScheduledVisitsSection — AO Dashboard field-visit planner.
// CRUD: Create (Quick Action) · Read (live list) · Update (accept request,
//       reschedule, mark completed) · Delete (swipe / menu to cancel; visits
//       involving a farmer are marked cancelled so the farmer sees it)
// ─────────────────────────────────────────────────────────────────────────────
class ScheduledVisitsSection extends ConsumerStatefulWidget {
  const ScheduledVisitsSection({super.key});

  @override
  ConsumerState<ScheduledVisitsSection> createState() => _ScheduledVisitsSectionState();
}

class _ScheduledVisitsSectionState extends ConsumerState<ScheduledVisitsSection> {
  // Hidden as soon as the cancel succeeds, so a swiped-away Dismissible is not
  // rebuilt from the previous stream data while the list refetches.
  final Set<String> _cancelledIds = {};

  String? get _me => Supabase.instance.client.auth.currentUser?.id;

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFEF4444) : _teal,
    ));
  }

  /// Runs a write, refreshes the list and reports the outcome.
  Future<bool> _run(BuildContext context, WidgetRef ref, Future<void> Function() action,
      String success) async {
    try {
      await action();
      ref.invalidate(officerVisitsProvider);
      if (context.mounted) _snack(context, success);
      return true;
    } catch (e) {
      if (context.mounted) {
        _snack(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
      return false;
    }
  }

  Future<void> _openScheduleSheet(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ScheduleVisitSheet(),
    );
    if (created == true && context.mounted) {
      ref.invalidate(officerVisitsProvider);
      _snack(context, 'Visit scheduled.');
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, OfficerVisit v) async {
    final me = _me;
    if (me == null) return;
    final when = await pickVisitDateTime(context, initial: v.scheduledFor);
    if (when == null || !context.mounted) return;
    await _run(context, ref, () => ref.read(visitRepositoryProvider).acceptRequest(v.id, me, when),
        'Request accepted — visit to ${v.farmerName} scheduled.');
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, OfficerVisit v) async {
    final me = _me;
    if (me == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline this request?'),
        content: Text('${v.farmerName} will see that the visit was declined.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await _run(context, ref, () => ref.read(visitRepositoryProvider).declineRequest(v.id, me),
        'Request from ${v.farmerName} declined.');
    if (ok && mounted) setState(() => _cancelledIds.add(v.id));
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref, OfficerVisit v) async {
    final when = await pickVisitDateTime(context, initial: v.scheduledFor);
    if (when == null || !context.mounted) return;
    await _run(context, ref, () => ref.read(visitRepositoryProvider).reschedule(v.id, when),
        'Visit moved to ${DateFormat('EEE d MMM, h:mm a').format(when)}.');
  }

  Future<bool> _confirmAndDelete(BuildContext context, WidgetRef ref, OfficerVisit v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel this visit?'),
        content: Text(v.farmerId != null
            ? 'The visit to ${v.farmerName} will be cancelled and the farmer will see it as cancelled.'
            : 'The visit to ${v.farmerName} will be removed from your schedule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep visit')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel visit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;
    final ok = await _run(context, ref, () => ref.read(visitRepositoryProvider).cancelVisit(v),
        'Visit cancelled.');
    if (ok && mounted) setState(() => _cancelledIds.add(v.id));
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(officerVisitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(en: 'Scheduled Visits', si: 'සැලසුම් කළ සංචාර', ta: 'திட்டமிட்ட வருகைகள்'),
                style: AppTextStyles.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openScheduleSheet(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.tr(en: 'Quick Action', si: 'ඉක්මන් ක්‍රියාව', ta: 'விரைவு செயல்')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        visitsAsync.when(
          loading: () => Container(
            height: 96,
            decoration: _cardDecoration(),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _messageCard(
            Icons.wifi_off_rounded,
            'Could not load visits.',
            action: TextButton(
              onPressed: () => ref.invalidate(officerVisitsProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (all) {
            final visits = all.where((v) => !_cancelledIds.contains(v.id)).toList();
            if (visits.isEmpty) {
              return _messageCard(
                Icons.event_available_rounded,
                'No visits planned. Tap Quick Action to schedule a field visit.',
              );
            }
            return Column(
              children: visits.map((v) {
                final tile = _VisitTile(
                  visit: v,
                  onAccept: () => _accept(context, ref, v),
                  onDecline: () => _decline(context, ref, v),
                  onReschedule: () => _reschedule(context, ref, v),
                  onComplete: () => _run(
                    context, ref,
                    () => ref.read(visitRepositoryProvider).markCompleted(v.id),
                    'Visit to ${v.farmerName} marked as completed.',
                  ),
                  onCancel: () => _confirmAndDelete(context, ref, v),
                );
                // Only the officer's own visits can be deleted (RLS).
                if (v.officerId != _me) return tile;
                return Dismissible(
                  key: ValueKey('visit_${v.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmAndDelete(context, ref, v),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.event_busy_rounded, color: Colors.white, size: 28),
                  ),
                  child: tile,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _messageCard(IconData icon, String text, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: _teal),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
          ?action,
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    );

/// Date then time picker; returns null if either is dismissed.
Future<DateTime?> pickVisitDateTime(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  final start = initial != null && initial.isAfter(now)
      ? initial
      : DateTime(now.year, now.month, now.day + 1, 9);
  final date = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 180)),
    helpText: 'Visit date',
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(start),
    helpText: 'Visit time',
  );
  if (time == null || !context.mounted) return null;
  final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  if (picked.isBefore(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('That time has already passed. Please choose a future time.'),
      backgroundColor: Color(0xFFEF4444),
    ));
    return null;
  }
  return picked;
}

// ─────────────────────────────────────────────────────────────────────────────
// One visit row
// ─────────────────────────────────────────────────────────────────────────────
class _VisitTile extends StatelessWidget {
  final OfficerVisit visit;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onReschedule;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _VisitTile({
    required this.visit,
    required this.onAccept,
    required this.onDecline,
    required this.onReschedule,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final date = v.scheduledFor;
    final accent = v.isRequest
        ? _terracotta
        : v.isCompleted
            ? Colors.grey
            : v.isOverdue
                ? const Color(0xFFDC2626)
                : _teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration().copyWith(
        border: Border.all(
          color: v.isRequest ? _terracotta.withValues(alpha: 0.5) : Colors.white,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  date != null ? DateFormat('MMM').format(date).toUpperCase() : 'NEW',
                  style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w800),
                ),
                Text(
                  date != null ? '${date.day}' : '•',
                  style: AppTextStyles.headlineMedium.copyWith(color: accent, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.farmerName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    decoration: v.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (v.village != null && v.village!.isNotEmpty) v.village!,
                    if (date != null) DateFormat('EEE, h:mm a').format(date),
                  ].join(' • '),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (v.reason != null && v.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(v.reason!, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                if (v.isRequest) ...[
                  _chip(
                    v.scheduledFor != null
                        ? 'Farmer request • prefers ${DateFormat('d MMM').format(v.scheduledFor!)}'
                        : 'Farmer request',
                    _terracotta,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.event_available_rounded, size: 18),
                          label: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ]
                else
                  _chip(
                    v.isCompleted ? 'Completed' : (v.isOverdue ? 'Overdue' : 'Scheduled'),
                    accent,
                  ),
              ],
            ),
          ),
          if (!v.isRequest)
            PopupMenuButton<String>(
              tooltip: 'Visit options',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'reschedule':
                    onReschedule();
                  case 'complete':
                    onComplete();
                  case 'cancel':
                    onCancel();
                }
              },
              itemBuilder: (_) => [
                if (!v.isCompleted) ...const [
                  PopupMenuItem(
                    value: 'reschedule',
                    child: ListTile(leading: Icon(Icons.edit_calendar_rounded), title: Text('Reschedule')),
                  ),
                  PopupMenuItem(
                    value: 'complete',
                    child: ListTile(leading: Icon(Icons.task_alt_rounded), title: Text('Mark completed')),
                  ),
                ],
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444)),
                    title: Text('Cancel visit', style: TextStyle(color: Color(0xFFEF4444))),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action: schedule a field visit (Create)
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleVisitSheet extends ConsumerStatefulWidget {
  const _ScheduleVisitSheet();

  @override
  ConsumerState<_ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends ConsumerState<_ScheduleVisitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _farmerCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  Consultation? _linkedCase;
  DateTime? _when;
  bool _saving = false;
  bool _triedSubmit = false;

  @override
  void dispose() {
    _farmerCtrl.dispose();
    _villageCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _linkCase(Consultation? c) {
    setState(() => _linkedCase = c);
    if (c == null) return;
    _farmerCtrl.text = c.farmerName ?? _farmerCtrl.text;
    _villageCtrl.text = c.location ?? _villageCtrl.text;
    if (_reasonCtrl.text.trim().isEmpty && c.diseaseName != null) {
      _reasonCtrl.text = 'Field inspection: ${c.diseaseName}';
    }
  }

  Future<void> _pickWhen() async {
    final picked = await pickVisitDateTime(context, initial: _when);
    if (picked != null) setState(() => _when = picked);
  }

  Future<void> _save() async {
    setState(() => _triedSubmit = true);
    final valid = _formKey.currentState!.validate();
    if (!valid || _when == null) return;

    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(visitRepositoryProvider).scheduleVisit(
            officerId: me,
            farmerName: _farmerCtrl.text.trim(),
            village: _villageCtrl.text.trim(),
            reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
            scheduledFor: _when!,
            farmerId: _linkedCase?.farmerId,
            consultationId: _linkedCase?.id,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Visit could not be saved. Check your connection and try again.'),
        backgroundColor: Color(0xFFEF4444),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final myCases = (ref.watch(consultationsProvider(null)).valueOrNull ?? [])
        .where((c) => c.officerId == me && !c.isClosed)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Schedule Field Visit', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Plan an on-site inspection. It appears under Scheduled Visits.',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 20),

                  if (myCases.isNotEmpty) ...[
                    DropdownButtonFormField<Consultation?>(
                      initialValue: _linkedCase,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Link to one of my cases (optional)',
                        prefixIcon: Icon(Icons.link_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Consultation?>(value: null, child: Text('No linked case')),
                        ...myCases.map((c) => DropdownMenuItem<Consultation?>(
                              value: c,
                              child: Text('${c.farmerName ?? 'Farmer'} — ${c.diseaseName ?? 'Case'}',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: _linkCase,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _farmerCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Farmer name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the farmer\'s name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _villageCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Village / location *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter where the visit is' : null,
                  ),
                  const SizedBox(height: 16),

                  // Date & time
                  InkWell(
                    onTap: _pickWhen,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date & time *',
                        prefixIcon: const Icon(Icons.event_rounded),
                        border: const OutlineInputBorder(),
                        errorText: _triedSubmit && _when == null ? 'Choose when you will visit' : null,
                      ),
                      child: Text(
                        _when != null
                            ? DateFormat('EEE d MMM yyyy, h:mm a').format(_when!)
                            : 'Tap to choose',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: _when != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Purpose (optional)',
                      hintText: 'e.g. Check spread of leaf blight, collect samples',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.event_available_rounded),
                    label: Text(_saving ? 'Saving…' : 'Schedule Visit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
