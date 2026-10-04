import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/models/consultation.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConsultationStatusScreen — farmer tracks one request live.
// CRUD: Read (status + officer replies, realtime) · Create (farmer reply)
//       · Update (cancel a request no officer has accepted yet)
// ─────────────────────────────────────────────────────────────────────────────
class ConsultationStatusScreen extends ConsumerStatefulWidget {
  final String consultationId;

  const ConsultationStatusScreen({super.key, required this.consultationId});

  @override
  ConsumerState<ConsultationStatusScreen> createState() => _ConsultationStatusScreenState();
}

class _ConsultationStatusScreenState extends ConsumerState<ConsultationStatusScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  bool _cancelling = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFEF4444) : AppColors.primary,
    ));
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (text.isEmpty || userId == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(consultationRepositoryProvider).sendMessage(
            consultationId: widget.consultationId,
            senderId: userId,
            senderRole: 'farmer',
            content: text,
          );
      _replyCtrl.clear();
    } catch (e) {
      _snack('Message not sent. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel this request?'),
        content: const Text('Officers will no longer see it as waiting. You can send a new request at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep request')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(consultationRepositoryProvider).cancelConsultation(widget.consultationId);
      _snack('Request cancelled.');
    } catch (e) {
      _snack('An officer has already picked up this request, so it can no longer be cancelled.', isError: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationAsync = ref.watch(liveConsultationProvider(widget.consultationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        onBackPressed: () => Navigator.pop(context),
        title: Text(context.tr(en: 'Consultation Status', si: 'උපදේශන තත්ත්වය', ta: 'ஆலோசனை நிலை')),
        actions: const [LanguageSelectorButton()],
      ),
      body: consultationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildCentered(Icons.wifi_off_rounded, 'Could not load this request.'),
        data: (c) {
          if (c == null) return _buildCentered(Icons.search_off_rounded, 'This request no longer exists.');
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(c),
                    const SizedBox(height: 16),
                    _buildDetails(c),
                    const SizedBox(height: 24),
                    Text('Timeline', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    ..._buildTimeline(c),
                    const SizedBox(height: 24),
                    Text('Conversation', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    _buildMessages(c),
                    if (c.isPending) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _cancelling ? null : _cancelRequest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(_cancelling ? 'Cancelling…' : 'Cancel Request'),
                      ),
                    ],
                  ],
                ),
              ),
              if (!c.isClosed) _buildReplyBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Consultation c) {
    final (label, color) = consultationStatusStyle(c);
    final (icon, title, body) = switch (c.status) {
      'resolved' => (Icons.task_alt_rounded, 'Advice Ready', 'The officer has answered your request. Read the advice below.'),
      'cancelled' => (Icons.cancel_rounded, 'Request Cancelled', 'You cancelled this request.'),
      'open' => (Icons.manage_search_rounded, 'Under Review', '${c.officerName ?? 'An officer'} is reviewing your case.'),
      _ => (Icons.hourglass_top_rounded, 'Submitted Successfully', 'Your case is in the officer inbox. You will be notified when an officer picks it up.'),
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _card(),
      child: Column(
        children: [
          CircleAvatar(radius: 32, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Consultation c) {
    final severity = (c.severity ?? 'medium');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.diseaseName ?? 'Crop problem', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          _detailRow(Icons.priority_high_rounded, 'Severity', '${severity[0].toUpperCase()}${severity.substring(1)}'),
          if (c.location != null && c.location!.isNotEmpty) _detailRow(Icons.location_on_outlined, 'Location', c.location!),
          _detailRow(Icons.schedule_rounded, 'Submitted', DateFormat('d MMM yyyy, h:mm a').format(c.createdAt.toLocal())),
          if (c.notes != null && c.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Text(c.notes!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodyMedium),
          Expanded(child: Text(value, style: AppTextStyles.titleSmall)),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(Consultation c) {
    final fmt = DateFormat('d MMM, h:mm a');
    if (c.isCancelled) {
      return [
        _timelineStep('Request Submitted', fmt.format(c.createdAt.toLocal()), true, false),
        _timelineStep('Cancelled by you', '', true, true),
      ];
    }
    return [
      _timelineStep('Request Submitted', fmt.format(c.createdAt.toLocal()), true, false),
      _timelineStep(
        'Under Review by Officer',
        c.officerId != null ? (c.officerName ?? 'Officer assigned') : 'Waiting for an officer',
        c.officerId != null || c.isResolved,
        false,
      ),
      _timelineStep(
        'Diagnosis & Advice Ready',
        c.resolvedAt != null ? fmt.format(c.resolvedAt!.toLocal()) : 'Pending',
        c.isResolved,
        true,
      ),
    ];
  }

  Widget _timelineStep(String title, String subtitle, bool done, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.secondary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: done ? AppColors.secondary : AppColors.divider, width: 2),
              ),
              child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
            if (!isLast) Container(width: 2, height: 40, color: done ? AppColors.secondary : AppColors.divider),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall.copyWith(color: done ? AppColors.textPrimary : AppColors.textSecondary)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessages(Consultation c) {
    final messagesAsync = ref.watch(consultationMessagesProvider(c.id));
    return messagesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text('Could not load messages.', style: AppTextStyles.bodyMedium),
      data: (messages) {
        if (messages.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Text(
              c.isClosed ? 'No messages on this request.' : 'No replies yet. The officer\'s advice will appear here.',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }
        return Column(children: messages.map(_messageBubble).toList());
      },
    );
  }

  Widget _messageBubble(ConsultationMessage m) {
    final fromOfficer = m.isFromOfficer;
    return Align(
      alignment: fromOfficer ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fromOfficer ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromOfficer ? 'Officer' : 'You',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: fromOfficer ? AppColors.primary : Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(m.content, style: AppTextStyles.bodyMedium.copyWith(color: fromOfficer ? AppColors.textPrimary : Colors.white)),
            const SizedBox(height: 4),
            Text(m.timeString, style: AppTextStyles.bodySmall.copyWith(color: fromOfficer ? AppColors.textSecondary : Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add more details for the officer…',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: _sending ? null : _sendReply,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentered(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      );
}
