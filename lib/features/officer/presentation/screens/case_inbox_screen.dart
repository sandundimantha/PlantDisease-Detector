import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/models/consultation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CaseInboxScreen — Real data from Supabase + working filters
// CRUD: Read (case list) · Update (accept case) · Delete (swipe to delete)
// ─────────────────────────────────────────────────────────────────────────────
class CaseInboxScreen extends ConsumerStatefulWidget {
  const CaseInboxScreen({super.key});

  @override
  ConsumerState<CaseInboxScreen> createState() => _CaseInboxScreenState();
}

class _CaseInboxScreenState extends ConsumerState<CaseInboxScreen> {
  String _selectedFilter = 'all'; // all | pending | resolved | urgent

  // Hidden immediately on swipe so the Dismissible leaves the tree before the
  // provider finishes refetching.
  final Set<String> _deletedIds = {};
  final Set<String> _acceptingIds = {};

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  void _refreshCases() {
    ref.invalidate(consultationsProvider(null));
    ref.invalidate(officerStatsProvider);
  }

  void _showResult(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
    ));
  }

  // ── Update: assign this officer to the case and mark it in progress ───────
  Future<void> _acceptCase(Consultation c) async {
    final officerId = _currentUserId;
    if (officerId == null) {
      _showResult('Please log in again to accept cases.', isError: true);
      return;
    }
    setState(() => _acceptingIds.add(c.id));
    try {
      await ref.read(consultationRepositoryProvider).assignOfficer(c.id, officerId);
      _showResult('Case accepted — ${c.farmerName ?? 'farmer'} has been assigned to you.');
      _refreshCases();
    } catch (e) {
      // Usually the inbox was stale (case cancelled or taken): say so and refresh.
      _showResult(e.toString().replaceFirst('Exception: ', ''), isError: true);
      _refreshCases();
    } finally {
      if (mounted) setState(() => _acceptingIds.remove(c.id));
    }
  }

  Future<bool> _confirmDelete(Consultation c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr(en: 'Delete this case?', si: 'මෙම නඩුව මකන්නද?', ta: 'இந்த வழக்கை நீக்கவா?')),
        content: Text(
          'The case from ${c.farmerName ?? 'this farmer'} and its chat history will be '
          'permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr(en: 'Cancel', si: 'අවලංගු කරන්න', ta: 'ரத்து செய்')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr(en: 'Delete', si: 'මකන්න', ta: 'நீக்கு')),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    // ── Delete ──────────────────────────────────────────────────────────────
    try {
      await ref.read(consultationRepositoryProvider).deleteConsultation(c.id);
      setState(() => _deletedIds.add(c.id));
      _showResult('Case deleted.');
      _refreshCases();
      return true;
    } catch (e) {
      _showResult('Could not delete case. Please try again.', isError: true);
      return false;
    }
  }

  List<Consultation> _applyFilter(List<Consultation> all) {
    final consultations = all.where((c) => !_deletedIds.contains(c.id)).toList();
    switch (_selectedFilter) {
      case 'urgent':
        return consultations.where((c) => c.needsUrgentAttention).toList();
      case 'pending':
        return consultations.where((c) => c.isPending || c.isOpen).toList();
      case 'resolved':
        return consultations.where((c) => c.isResolved).toList();
      default:
        return consultations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultationsAsync = ref.watch(consultationsProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background blob
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD9734E).withValues(alpha: 0.06),
                ),
              ),
            ),

            Column(
              children: [
                _buildAppBar(context),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(context, label: context.tr(en: 'All Cases', si: 'සියලු නඩු', ta: 'அனைத்து வழக்குகள்'), filter: 'all'),
                      const SizedBox(width: 12),
                      _buildFilterChip(context, label: context.tr(en: 'Urgent', si: 'හදිසි', ta: 'அவசரம்'), filter: 'urgent',
                          color: const Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      _buildFilterChip(context, label: context.tr(en: 'Pending', si: 'පොරොත්තුවෙන්', ta: 'நிலுவையில்'), filter: 'pending',
                          color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      _buildFilterChip(context, label: context.tr(en: 'Resolved', si: 'විසඳා ඇත', ta: 'தீர்க்கப்பட்டது'), filter: 'resolved',
                          color: const Color(0xFF10B981)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 24, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.swipe_left_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(context.tr(en: 'Swipe a closed case left to delete it', si: 'වසා දැමූ නඩුවක් මැකීමට වමට ස්වයිප් කරන්න', ta: 'மூடப்பட்ட வழக்கை நீக்க இடதுபுறம் இழுக்கவும்'),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: consultationsAsync.when(
                    loading: () => _buildLoadingList(),
                    error: (_, _e) => _buildErrorState(context),
                    data: (consultations) {
                      final filtered = _applyFilter(consultations);
                      if (filtered.isEmpty) return _buildEmptyState(context);
                      return ListView.builder(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final tile = _buildCaseTile(context, c, index);
                          // RLS: only closed cases that are unassigned or the officer's
                          // own can be deleted, so an open farmer request is never lost.
                          final canDelete = c.isClosed &&
                              (c.officerId == null || c.officerId == _currentUserId);
                          if (!canDelete) {
                            return Padding(padding: const EdgeInsets.only(bottom: 16), child: tile);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Dismissible(
                              key: ValueKey('case_${c.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(c),
                              background: _buildDeleteBackground(),
                              child: tile,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (context.canPop()) ...[
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                context.tr(en: 'Case Inbox', si: 'නඩු ලිපිගොනු', ta: 'வழக்குகள்'),
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.refresh(consultationsProvider(null)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                    onPressed: () => ref.refresh(consultationsProvider(null)),
                    tooltip: 'Refresh',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const LanguageSelectorButton(isCompact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context,
      {required String label, required String filter, Color? color}) {
    final isSelected = _selectedFilter == filter;
    final activeColor = color ?? const Color(0xFF0F766E);
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
      itemCount: 5,
      itemBuilder: (_, _i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildSkeletonTile(),
      ),
    );
  }

  Widget _buildSkeletonTile() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(height: 12, width: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6))),
                Container(height: 16, width: 160,
                    decoration: BoxDecoration(color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6))),
                Container(height: 12, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, size: 56,
                color: Color(0xFF0F766E)),
          ),
          const SizedBox(height: 20),
          Text(context.tr(en: 'No Cases Found', si: 'නඩු හමු නොවීය', ta: 'வழக்குகள் எதுவும் இல்லை'),
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('No ${_selectedFilter == 'all' ? '' : _selectedFilter} cases at the moment.',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(context.tr(en: 'Failed to load cases', si: 'නඩු පූරණය කළ නොහැක', ta: 'வழக்குகளை ஏற்ற முடியவில்லை'),
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.refresh(consultationsProvider(null)),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr(en: 'Retry', si: 'නැවත උත්සාහ කරන්න', ta: 'மீண்டும் முயற்சி')),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTile(BuildContext context, Consultation c, int index) {
    return GestureDetector(
      onTap: () => context.push('/case_detail', extra: c),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: c.needsUrgentAttention
                ? const Color(0xFFFECACA)
                : Colors.white,
            width: c.needsUrgentAttention ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: c.needsUrgentAttention
                  ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Thumbnail
            Hero(
              tag: 'case_image_${c.id}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                  image: c.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(c.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: c.imageUrl == null
                    ? const Icon(Icons.eco_rounded, color: Color(0xFF0F766E), size: 36)
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.isResolved
                              ? const Color(0xFFDEF7EC)
                              : c.isCancelled
                                  ? Colors.grey.shade200
                                  : c.isUrgent
                                      ? const Color(0xFFFEE2E2)
                                      : c.isOpen
                                          ? const Color(0xFFDBEAFE)
                                          : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.isResolved
                              ? 'Resolved'
                              : c.isCancelled
                                  ? 'Cancelled'
                                  : c.isUrgent
                                      ? 'Urgent'
                                      : c.isOpen
                                          ? 'In Progress'
                                          : 'Pending',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: c.isResolved
                                ? const Color(0xFF046C4E)
                                : c.isCancelled
                                    ? Colors.grey.shade700
                                    : c.isUrgent
                                        ? const Color(0xFF991B1B)
                                        : c.isOpen
                                            ? const Color(0xFF1E40AF)
                                            : const Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Time ago
                      Text(
                        c.timeAgo,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Farmer name
                  Text(
                    c.farmerName ?? 'Unknown Farmer',
                    style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),

                  // Disease / description
                  Text(
                    c.diseaseName != null
                        ? 'Suspected: ${c.diseaseName}${c.location != null ? ' • ${c.location}' : ''}'
                        : 'Awaiting diagnosis${c.location != null ? ' • ${c.location}' : ''}',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!c.isClosed) ...[
                    const SizedBox(height: 12),
                    _buildAssignmentAction(c),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentAction(Consultation c) {
    if (c.officerId != null) {
      final isMine = c.officerId == _currentUserId;
      return Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 16,
              color: isMine ? const Color(0xFF0F766E) : AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isMine ? 'Assigned to you' : 'Assigned to ${c.officerName ?? 'another officer'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isMine ? const Color(0xFF0F766E) : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final isLoading = _acceptingIds.contains(c.id);
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading ? null : () => _acceptCase(c),
        icon: isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.assignment_turned_in_rounded, size: 18),
        label: Text(isLoading ? 'Accepting…' : 'Accept Case'),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(context.tr(en: 'Delete', si: 'මකන්න', ta: 'நீக்கு'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
