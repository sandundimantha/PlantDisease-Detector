import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/database/app_database.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/database_provider.dart';
import 'package:plant_disease_detector/core/providers/connectivity_provider.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SyncStatusScreen — scans saved on the phone that are waiting to upload.
// ─────────────────────────────────────────────────────────────────────────────
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    final messenger = ScaffoldMessenger.of(context);
    final doneText = context.tr(en: 'Sync finished', si: 'සමමුහුර්තය අවසන්', ta: 'ஒத்திசைவு முடிந்தது');
    setState(() => _syncing = true);
    await ref.read(outboxProcessorProvider).processOutbox();
    ref.invalidate(scanHistoryProvider);
    if (!mounted) return;
    setState(() => _syncing = false);
    messenger.showSnackBar(SnackBar(content: Text(doneText), backgroundColor: AppColors.primary));
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    final pendingAsync = ref.watch(pendingUploadsProvider);
    final pending = pendingAsync.valueOrNull ?? const <OutboxData>[];

    final (icon, color, title, body) = !online
        ? (
            Icons.wifi_off_rounded,
            AppColors.warning,
            context.tr(en: 'You are offline', si: 'ඔබ නොබැඳි තත්ත්වයේ සිටී', ta: 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்'),
            context.tr(
              en: 'You can keep scanning. Results are saved on this phone and upload when you are back online.',
              si: 'ඔබට දිගටම ස්කෑන් කළ හැක. ප්‍රතිඵල මෙම දුරකථනයේ සුරැකෙන අතර නැවත සම්බන්ධ වූ විට යවනු ලැබේ.',
              ta: 'நீங்கள் தொடர்ந்து ஸ்கேன் செய்யலாம். முடிவுகள் இந்தத் தொலைபேசியில் சேமிக்கப்பட்டு, இணையம் திரும்பியதும் பதிவேற்றப்படும்.',
            ),
          )
        : pending.isEmpty
            ? (
                Icons.cloud_done_rounded,
                AppColors.primary,
                context.tr(en: 'Everything is up to date', si: 'සියල්ල යාවත්කාලීනයි', ta: 'அனைத்தும் புதுப்பிக்கப்பட்டுள்ளன'),
                context.tr(
                  en: 'All your scans are saved to your account.',
                  si: 'ඔබේ සියලු ස්කෑන් ඔබේ ගිණුමට සුරැකී ඇත.',
                  ta: 'உங்கள் அனைத்து ஸ்கேன்களும் உங்கள் கணக்கில் சேமிக்கப்பட்டுள்ளன.',
                ),
              )
            : (
                Icons.cloud_upload_rounded,
                AppColors.warning,
                context.tr(en: '${pending.length} waiting to upload', si: 'උඩුගත කිරීමට ${pending.length}ක් ඇත', ta: '${pending.length} பதிவேற்றக் காத்திருக்கின்றன'),
                context.tr(
                  en: 'Tap Sync Now to upload them.',
                  si: 'ඒවා උඩුගත කිරීමට "දැන් සමමුහුර්ත කරන්න" ඔබන්න.',
                  ta: 'அவற்றைப் பதிவேற்ற "இப்போது ஒத்திசை" என்பதைத் தட்டவும்.',
                ),
              );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Offline & Sync', si: 'නොබැඳි සහ සමමුහුර්තය', ta: 'ஆஃப்லைன் & ஒத்திசைவு')),
        actions: const [LanguageSelectorButton(isCompact: true)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(title, style: AppTextStyles.headlineMedium.copyWith(fontSize: 20), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(body, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(context.tr(en: 'Waiting to upload', si: 'උඩුගත කිරීමට ඇති', ta: 'பதிவேற்றக் காத்திருப்பவை'), style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            for (final item in pending) _buildQueueItem(context, item),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: (!online || _syncing || pending.isEmpty) ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync_rounded, color: Colors.white),
            label: Text(
              context.tr(en: 'Sync Now', si: 'දැන් සමමුහුර්ත කරන්න', ta: 'இப்போது ஒத்திசை'),
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(BuildContext context, OutboxData item) {
    String name = context.tr(en: 'Scan result', si: 'ස්කෑන් ප්‍රතිඵලය', ta: 'ஸ்கேன் முடிவு');
    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final disease = (payload['disease_name'] ?? payload['disease']) as String?;
      if (disease != null) name = context.trDisease(disease);
    } catch (_) {}
    final failed = item.status == 'failed';
    final t = item.createdAt.toLocal();
    final when = '${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_upload_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(when, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            failed
                ? context.tr(en: 'Retrying', si: 'නැවත උත්සාහ', ta: 'மீண்டும் முயற்சி')
                : context.tr(en: 'Waiting', si: 'රැඳී සිටී', ta: 'காத்திருக்கிறது'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
