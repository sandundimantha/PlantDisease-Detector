import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/features/officer/application/chat_notifier.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/models/consultation.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CaseDetailScreen — Real-time chat with Supabase Realtime
// ─────────────────────────────────────────────────────────────────────────────
class CaseDetailScreen extends ConsumerStatefulWidget {
  final Consultation? consultation; // passed via GoRouter extra

  const CaseDetailScreen({super.key, this.consultation});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _chatInitialized = false;

  Consultation? get _consultation => widget.consultation;

  @override
  void initState() {
    super.initState();
    if (_consultation != null) {
      // Initialize chat after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
    }
  }

  void _initializeChat() {
    if (_chatInitialized || _consultation == null) return;
    _chatInitialized = true;
    ref.read(chatProvider(_consultation!.id).notifier).initialize(_consultation!.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Looks up the farmer's phone number on their profile and opens the dialer.
  Future<void> _callFarmer(Consultation? c) async {
    if (c == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final noPhone = context.tr(
      en: 'This farmer has not added a phone number. Use the chat below.',
      si: 'මෙම ගොවියා දුරකථන අංකයක් එක් කර නැත. පහත චැට් භාවිතා කරන්න.',
      ta: 'இந்த விவசாயி தொலைபேசி எண்ணைச் சேர்க்கவில்லை. கீழே உள்ள அரட்டையைப் பயன்படுத்தவும்.',
    );
    try {
      final row = await Supabase.instance.client.from('profiles').select('phone').eq('id', c.farmerId).maybeSingle();
      final phone = (row?['phone'] as String?)?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
      if (phone.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(noPhone)));
        return;
      }
      if (!await launchUrl(Uri(scheme: 'tel', path: phone))) {
        messenger.showSnackBar(SnackBar(content: Text(phone)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(noPhone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Top Image Background
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Hero(
              tag: 'case_image_${_consultation?.id ?? 'detail'}',
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      _consultation?.imageUrl ??
                          'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?q=80&w=600&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.2),
                        const Color(0xFFF8FAFC),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPredictionCard(),
                      _buildChatSection(context),
                    ],
                  ),
                ),
                _buildBottomInputArea(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The officer can reply and resolve only while the case is open and is
  // unassigned or theirs (the same rule RLS enforces).
  bool get _canAct {
    final c = _consultation;
    if (c == null || c.isClosed) return false;
    final me = Supabase.instance.client.auth.currentUser?.id;
    return c.officerId == null || c.officerId == me;
  }

  String get _lockedReason {
    final c = _consultation;
    if (c == null) return '';
    if (c.isResolved) return 'CASE RESOLVED';
    if (c.isCancelled) return 'CANCELLED BY FARMER';
    return 'ASSIGNED TO ${(c.officerName ?? 'ANOTHER OFFICER').toUpperCase()}';
  }

  // Inbox and dashboard cache their lists; refetch so a resolved case moves
  // out of "Urgent" / "Pending" straight away.
  void _refreshCaseLists() {
    ref.invalidate(consultationsProvider(null));
    ref.invalidate(officerStatsProvider);
  }

  // ── Update: close the case; only report success if the row changed ────────
  Future<void> _resolveCase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatProvider(_consultation!.id).notifier).markResolved();
      _refreshCaseLists();
      messenger.showSnackBar(SnackBar(content: Text(context.tr(en: '✅ Case marked as resolved!', si: '✅ නඩුව විසඳූ ලෙස සලකුණු කළා!', ta: '✅ வழக்கு தீர்க்கப்பட்டதாகக் குறிக்கப்பட்டது!'))));
      if (mounted && context.canPop()) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(context.tr(en: 'Case could not be resolved. Check your connection and try again.', si: 'නඩුව විසඳිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'வழக்கைத் தீர்க்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.')),
        backgroundColor: Color(0xFFEF4444),
      ));
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () { if (context.canPop()) context.pop(); },
          ),
          Text(
            context.tr(en: 'Case Details', si: 'නඩු විස්තර', ta: 'வழக்கு விவரங்கள்'),
            style: AppTextStyles.titleMedium.copyWith(
                fontSize: 20, color: Colors.white,
                fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          _buildGlassIconButton(
            icon: Icons.more_horiz_rounded,
            onPressed: () => _showCaseOptions(context),
          ),
        ],
      ),
    );
  }

  void _showCaseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10))),
            ListTile(
              leading: const Icon(Icons.medical_services_rounded, color: Color(0xFFD9734E)),
              title: Text(context.tr(en: 'Suggest Treatment', si: 'ප්‍රතිකාර යෝජනා කරන්න', ta: 'சிகிச்சையைப் பரிந்துரை')),
              onTap: () { Navigator.pop(context); _showPesticideSuggestion(context); },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              title: Text(context.tr(en: 'Mark as Resolved', si: 'විසඳූ ලෙස සලකුණු කරන්න', ta: 'தீர்க்கப்பட்டதாகக் குறி')),
              onTap: () async {
                Navigator.pop(context);
                if (_canAct) {
                  await _resolveCase();
                } else if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: Text('This case can no longer be resolved ($_lockedReason).'),
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPesticideSuggestion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)))),
            Text(context.tr(en: 'Treatment Recommendation', si: 'ප්‍රතිකාර නිර්දේශය', ta: 'சிகிச்சைப் பரிந்துரை'),
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_consultation?.diseaseName ?? 'Disease',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            _treatmentItem('🧪', 'Apply Mancozeb 2g/L water', 'Spray every 7 days'),
            _treatmentItem('💧', 'Improve drainage', 'Prevent water logging around plants'),
            _treatmentItem('🌿', 'Remove infected leaves', 'Burn to prevent spread'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _treatmentItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final c = _consultation;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              blurRadius: 30, offset: const Offset(0, 15)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status + severity row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c?.needsUrgentAttention == true
                            ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: c?.needsUrgentAttention == true
                              ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c?.needsUrgentAttention == true
                                ? Icons.emergency_rounded : Icons.pending_rounded,
                            color: c?.needsUrgentAttention == true
                                ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c?.needsUrgentAttention == true ? 'URGENT'
                                : c?.isResolved == true
                                    ? 'RESOLVED'
                                    : c?.isCancelled == true ? 'CANCELLED' : 'PENDING',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: c?.needsUrgentAttention == true
                                  ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c?.severity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF042F2E)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                              blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          '${c!.severity![0].toUpperCase()}${c.severity!.substring(1)} Severity',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Disease name
                Text(
                  c?.diseaseName ?? 'Awaiting Diagnosis',
                  style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 16),

                // Farmer info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFD9734E).withValues(alpha: 0.2),
                        backgroundImage: c?.farmerAvatar != null
                            ? NetworkImage(c!.farmerAvatar!) : null,
                        child: c?.farmerAvatar == null
                            ? Text(
                                (c?.farmerName?.isNotEmpty == true)
                                    ? c!.farmerName![0].toUpperCase() : 'F',
                                style: AppTextStyles.titleMedium.copyWith(
                                    color: const Color(0xFFD9734E),
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c?.farmerName ?? 'Farmer',
                              style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${c?.location ?? 'Unknown Location'} • ${c?.timeAgo ?? ''}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _callFarmer(c),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded,
                              color: Color(0xFF0F766E), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                // Farmer's own description from the Expert Consult request.
                if (c?.notes != null && c!.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farmer\'s notes',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(c.notes!, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection(BuildContext context) {
    final chatAsync = _consultation != null
        ? ref.watch(chatProvider(_consultation!.id))
        : null;

    // Auto-scroll on new messages
    if (chatAsync?.hasValue == true) {
      _scrollToBottom();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 20),
              width: 50, height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF0F766E), size: 18),
                const SizedBox(width: 8),
                Text(context.tr(en: 'Consultation Chat', si: 'උපදේශන චැට්', ta: 'ஆலோசனை அரட்டை'),
                    style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F766E))),
                const Spacer(),
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 6),
                Text(context.tr(en: 'Live', si: 'සජීවී', ta: 'நேரலை'), style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chat Messages
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _consultation == null
                ? _buildNoCaseState()
                : chatAsync!.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('Failed to load chat: $e',
                            style: AppTextStyles.bodyMedium),
                      ),
                    ),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return _buildNoChatMessages();
                      }
                      return Column(
                        children: messages
                            .map((msg) => _buildChatBubble(msg))
                            .toList(),
                      );
                    },
                  ),
          ),

          // Suggest Pesticide button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD9734E), Color(0xFF9C4927)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFD9734E).withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showPesticideSuggestion(context),
                      icon: const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 20),
                      label: Text(context.tr(en: 'Suggest Treatment', si: 'ප්‍රතිකාර යෝජනා කරන්න', ta: 'சிகிச்சையைப் பரிந்துரை'),
                          style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNoCaseState() {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(context.tr(en: 'No case selected', si: 'නඩුවක් තෝරා නැත', ta: 'வழக்கு தேர்ந்தெடுக்கப்படவில்லை'), style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildNoChatMessages() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: Color(0xFF0F766E)),
          const SizedBox(height: 12),
          Text(context.tr(en: 'No messages yet', si: 'තවම පණිවිඩ නැත', ta: 'இன்னும் செய்திகள் இல்லை'),
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(context.tr(en: 'Start the consultation by sending a message.', si: 'පණිවිඩයක් යවා උපදේශනය ආරම්භ කරන්න.', ta: 'ஒரு செய்தியை அனுப்பி ஆலோசனையைத் தொடங்குங்கள்.'),
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message input row
          if (_canAct) Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _chatController,
                    enabled: _consultation != null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(currentUserId),
                    decoration: InputDecoration(
                      hintText: _consultation != null
                          ? 'Type your message...'
                          : 'Select a case to chat',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _sendMessage(currentUserId),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF042F2E)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          // Mark as Resolved button
          if (_canAct) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _resolveCase,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 2),
                  ),
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 8),
                    Text(context.tr(en: 'MARK AS RESOLVED', si: 'විසඳූ ලෙස සලකුණු කරන්න', ta: 'தீர்க்கப்பட்டதாகக் குறி'),
                        style: AppTextStyles.titleMedium.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ],

          // Locked: resolved, cancelled or another officer's case
          if (_consultation != null && !_canAct) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _consultation!.isResolved ? const Color(0xFFDEF7EC) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_consultation!.isResolved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      color: _consultation!.isResolved ? const Color(0xFF046C4E) : Colors.grey.shade700,
                      size: 22),
                  const SizedBox(width: 8),
                  Text(_lockedReason,
                      style: AppTextStyles.titleMedium.copyWith(
                          color: _consultation!.isResolved ? const Color(0xFF046C4E) : Colors.grey.shade700,
                          fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage(String? currentUserId) {
    if (_consultation == null || _chatController.text.trim().isEmpty) return;
    ref.read(chatProvider(_consultation!.id).notifier).sendMessage(
          content: _chatController.text,
          senderRole: 'officer', // This screen is officer side
        );
    _chatController.clear();
    _scrollToBottom();
  }

  Widget _buildChatBubble(ConsultationMessage msg) {
    final isOfficer = msg.isFromOfficer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isOfficer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          Padding(
            padding: EdgeInsets.only(
                left: isOfficer ? 0 : 4, right: isOfficer ? 4 : 0,
                bottom: 4),
            child: Text(
              isOfficer ? 'You (Officer)' : (msg.senderName ?? 'Farmer'),
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),

          Row(
            mainAxisAlignment:
                isOfficer ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Farmer avatar
              if (!isOfficer) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      const Color(0xFFD9734E).withValues(alpha: 0.2),
                  child: Text(
                    (msg.senderName?.isNotEmpty == true)
                        ? msg.senderName![0].toUpperCase() : 'F',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFD9734E),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Message bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    gradient: isOfficer
                        ? const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF042F2E)])
                        : const LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isOfficer ? 22 : 6),
                      bottomRight: Radius.circular(isOfficer ? 6 : 22),
                    ),
                    border:
                        isOfficer ? null : Border.all(color: Colors.grey.shade200),
                    boxShadow: isOfficer
                        ? [BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                            blurRadius: 10, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Text(
                    msg.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isOfficer ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Officer avatar
              if (isOfficer) ...[
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      const Color(0xFF0F766E).withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF0F766E), size: 16),
                ),
              ],
            ],
          ),

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
                left: isOfficer ? 0 : 42,
                right: isOfficer ? 42 : 0,
                top: 4),
            child: Text(msg.timeString,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
