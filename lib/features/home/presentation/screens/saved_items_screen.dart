// Saved Items screen — CRUD by Member A (IT23836518, Lanka Sri Deepthika)
// Read: list from Supabase · Update: edit a note · Delete: swipe or delete button
// (Create happens from the bookmark on Home → Recent Scans.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/home/application/saved_items_provider.dart';
import 'package:plant_disease_detector/features/home/data/saved_item.dart';

class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, savedAsync.valueOrNull?.length),
            const SizedBox(height: 16),
            Expanded(
              child: savedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (_, _) => _buildError(context, ref),
                data: (items) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.refresh(savedItemsProvider.future),
                  child: items.isEmpty
                      ? _buildEmpty(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _buildDismissibleCard(context, ref, items[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int? count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 8),
          // Title + count take all the room left of the language button.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    context.tr(en: 'Saved Items', si: 'සුරැකි අයිතම', ta: 'சேமிக்கப்பட்டவை'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 22, letterSpacing: -0.5),
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const LanguageSelectorButton(isCompact: true),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.bookmark_border_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(
          context.tr(en: 'No saved items yet', si: 'තවම සුරැකි අයිතම නැත', ta: 'இன்னும் சேமிக்கப்பட்டவை இல்லை'),
          textAlign: TextAlign.center,
          style: AppTextStyles.titleSmall.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            en: 'Tap the bookmark on a recent scan in Home to save it here.',
            si: 'මුල් පිටුවේ මෑත ස්කෑන් එකක පිටු සලකුණ ඔබා එය මෙහි සුරකින්න.',
            ta: 'முகப்பில் சமீபத்திய ஸ்கேனின் புத்தகக்குறியைத் தட்டி இங்கே சேமிக்கவும்.',
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              context.tr(en: 'Could not load saved items', si: 'සුරැකි අයිතම පූරණය කළ නොහැක', ta: 'சேமிக்கப்பட்டவற்றை ஏற்ற முடியவில்லை'),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(savedItemsProvider),
              child: Text(context.tr(en: 'Retry', si: 'නැවත උත්සාහ කරන්න', ta: 'மீண்டும் முயற்சி')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(BuildContext context, WidgetRef ref, SavedItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.signOutBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.signOutText),
      ),
      // Delete in the database first; only drop the card if that succeeded.
      confirmDismiss: (_) => _delete(context, ref, item),
      child: GestureDetector(
        onTap: () => _openNoteEditor(context, ref, item),
        child: _buildSavedCard(context, item),
      ),
    );
  }

  Widget _buildSavedCard(BuildContext context, SavedItem item) {
    final healthy = item.title.toLowerCase().contains('healthy');
    final gradient = healthy ? AppGradients.savedOrganic : AppGradients.savedWarning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background blob
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(healthy ? Icons.eco_rounded : Icons.coronavirus_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.trDisease(item.title), style: AppTextStyles.titleSmall.copyWith(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        if (item.note.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.note,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _addedText(context, item.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit_note_rounded, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              item.note.isEmpty
                                  ? context.tr(en: 'Add note', si: 'සටහනක්', ta: 'குறிப்பு')
                                  : context.tr(en: 'Edit note', si: 'සංස්කරණය', ta: 'திருத்து'),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete (with undo) ────────────────────────────────────────────────────
  Future<bool> _delete(BuildContext context, WidgetRef ref, SavedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(savedItemsProvider.notifier);
    final removedText = context.tr(en: 'Removed from saved items', si: 'සුරැකි අයිතම වලින් ඉවත් කළා', ta: 'சேமிக்கப்பட்டவையிலிருந்து நீக்கப்பட்டது');
    final undoText = context.tr(en: 'Undo', si: 'අහෝසි කරන්න', ta: 'செயல்தவிர்');
    final errorText = _errorText(context);
    try {
      await notifier.remove(item.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorText), backgroundColor: Colors.red));
      return false;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(removedText),
      action: SnackBarAction(
        label: undoText,
        onPressed: () async {
          try {
            await notifier.restore(item);
          } catch (_) {
            messenger.showSnackBar(SnackBar(content: Text(errorText), backgroundColor: Colors.red));
          }
        },
      ),
    ));
    return true;
  }

  // ── Update (note) ─────────────────────────────────────────────────────────
  Future<void> _openNoteEditor(BuildContext context, WidgetRef ref, SavedItem item) async {
    final result = await showModalBottomSheet<_NoteSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NoteSheet(item: item),
    );
    if (result == null || !context.mounted) return;

    if (result.delete) {
      await _delete(context, ref, item);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final savedText = context.tr(en: 'Note saved', si: 'සටහන සුරැකුණා', ta: 'குறிப்பு சேமிக்கப்பட்டது');
    final errorText = _errorText(context);
    try {
      await ref.read(savedItemsProvider.notifier).updateNote(item.id, result.note);
      messenger.showSnackBar(SnackBar(content: Text(savedText), backgroundColor: AppColors.primary));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorText), backgroundColor: Colors.red));
    }
  }

  String _addedText(BuildContext context, DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return context.tr(en: 'Added just now', si: 'දැන්', ta: 'இப்போது');
    }
    final String n;
    final String en, si, ta;
    if (diff.inHours < 1) {
      n = '${diff.inMinutes}';
      (en, si, ta) = ('m', 'මිනි.', 'நிமி.');
    } else if (diff.inDays < 1) {
      n = '${diff.inHours}';
      (en, si, ta) = ('h', 'පැය', 'மணி');
    } else if (diff.inDays < 7) {
      n = '${diff.inDays}';
      (en, si, ta) = ('d', 'දින', 'நாள்');
    } else {
      n = '${diff.inDays ~/ 7}';
      (en, si, ta) = ('w', 'සති', 'வாரம்');
    }
    return context.tr(en: 'Added $n$en ago', si: '$n $si කට පෙර', ta: '$n $ta முன்');
  }

  String _errorText(BuildContext context) => context.tr(
        en: 'Something went wrong. Please try again.',
        si: 'යමක් වැරදුණා. නැවත උත්සාහ කරන්න.',
        ta: 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',
      );
}

class _NoteSheetResult {
  final String note;
  final bool delete;
  const _NoteSheetResult({this.note = '', this.delete = false});
}

class _NoteSheet extends StatefulWidget {
  final SavedItem item;
  const _NoteSheet({required this.item});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.item.note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.trDisease(widget.item.title), style: AppTextStyles.headlineMedium.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(widget.item.subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Text(context.tr(en: 'My note', si: 'මගේ සටහන', ta: 'என் குறிப்பு'), style: AppTextStyles.titleSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.tr(
                en: 'e.g. Sprayed copper fungicide on Oct 6',
                si: 'උදා: ඔක් 6 වන දින තඹ දිලීර නාශක ඉසීය',
                ta: 'எ.கா: அக் 6 அன்று செப்பு பூஞ்சைக் கொல்லி தெளிக்கப்பட்டது',
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, const _NoteSheetResult(delete: true)),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.signOutText),
                  label: Text(
                    context.tr(en: 'Delete', si: 'මකන්න', ta: 'நீக்கு'),
                    style: const TextStyle(color: AppColors.signOutText),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.signOutText),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _NoteSheetResult(note: _controller.text)),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    context.tr(en: 'Save note', si: 'සටහන සුරකින්න', ta: 'குறிப்பைச் சேமி'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
