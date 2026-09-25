import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/models/disease_result.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryScreen — Matches Figma HistoryScreen.tsx
// ─────────────────────────────────────────────────────────────────────────────
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final List<String> _filters = const ["All", "High", "Medium", "Low", "None"];
  String _activeFilter = "All";

  List<ScanRecord> _filteredScans(List<ScanRecord> all) {
    if (_activeFilter == "All") return all;
    return all.where((s) => s.severity == _activeFilter.toLowerCase()).toList();
  }

  void _openScan(ScanRecord scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosticResultScreen(scan: scan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scanHistoryProvider);
    final filtered = _filteredScans(all);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(en: 'Scan History', si: 'පරීක්ෂණ ඉතිහාසය', ta: 'ஸ்கேன் வரலாறு'),
                    style: AppTextStyles.headlineMedium.copyWith(letterSpacing: -0.5, fontSize: 24),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      en: '${all.length} total scans',
                      si: 'සම්පූර්ණ පරීක්ෂණ ${all.length}ක්',
                      ta: 'மொத்தம் ${all.length} ஸ்கேன்கள்',
                    ),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.settingsIcon),
                  ),
                ],
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: _filters.map((f) {
                  final isActive = _activeFilter == f;
                  final rawLabel = f == "None" ? "Healthy" : f;
                  final label = switch (rawLabel) {
                    "All" => context.tr(en: 'All', si: 'සියල්ල', ta: 'அனைத்தும்'),
                    "High" => context.tr(en: 'High', si: 'ඉහළ', ta: 'அதிகம்'),
                    "Medium" => context.tr(en: 'Medium', si: 'මධ්‍යම', ta: 'நடுத்தரம்'),
                    "Low" => context.tr(en: 'Low', si: 'අඩු', ta: 'குறைவு'),
                    "Healthy" => context.tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியமானது'),
                    _ => rawLabel,
                  };
                  return GestureDetector(
                    onTap: () => setState(() => _activeFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                          else
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.settingsIcon,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Summary Bar
            _buildSummaryBar(),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌿', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(
                              en: 'No scans matching this filter',
                              si: 'මෙම පෙරහනට අදාළ පරීක්ෂණ නොමැත',
                              ta: 'இந்த வடிப்பானுக்கு ஸ்கேன்கள் எதுவும் இல்லை',
                            ),
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // Space for bottom nav
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr(en: 'Disease Rate', si: 'රෝග ප්‍රතිශතය', ta: 'நோய் விகிதம்'), style: AppTextStyles.titleSmall),
              Text(context.tr(en: 'This month', si: 'මෙම මාසයේ', ta: 'இந்த மாதம்'), style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: 17, child: Container(color: AppColors.severityHigh)),
                  Expanded(flex: 33, child: Container(color: AppColors.severityMedium)),
                  Expanded(flex: 17, child: Container(color: AppColors.severityLow)),
                  Expanded(flex: 33, child: Container(color: AppColors.severityDefault)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatLegend(context.tr(en: 'High', si: 'ඉහළ', ta: 'அதிகம்'), AppColors.severityHigh, '17%'),
              _buildStatLegend(context.tr(en: 'Medium', si: 'මධ්‍යම', ta: 'நடுத்தரம்'), AppColors.severityMedium, '33%'),
              _buildStatLegend(context.tr(en: 'Low', si: 'අඩු', ta: 'குறைவு'), AppColors.severityLow, '17%'),
              _buildStatLegend(context.tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியமானது'), AppColors.severityDefault, '33%'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatLegend(String label, Color color, String val) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(val, style: AppTextStyles.titleSmall.copyWith(fontSize: 12)),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHistoryCard(ScanRecord scan) {
    return GestureDetector(
      onTap: () => _openScan(scan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmartImage(src: scan.imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, scan.severityColor.withValues(alpha: 0.3)],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.trDisease(scan.diseaseName),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleSmall.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  scan.latinName == 'No pathogen detected'
                                      ? context.trSymptom(scan.latinName)
                                      : scan.latinName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scan.severityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              context.trSeverity(scan.severityLabel),
                              style: TextStyle(color: scan.severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${context.trDate(scan.dateLabel)} · 10:42 AM',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Text('${(scan.confidenceScore * 100).round()}%', style: AppTextStyles.titleSmall.copyWith(fontSize: 11)),
                              const SizedBox(width: 4),
                              Container(
                                width: 48,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.imageLoadingBg,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: scan.confidenceScore,
                                    child: Container(color: scan.severityColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(scan.fieldLocation, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              // Chevron
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.settingsChevron, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
