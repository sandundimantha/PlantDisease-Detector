import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/features/farm_log/application/farm_provider.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/widgets/farm_forms.dart';
import 'package:intl/intl.dart';
import 'package:plant_disease_detector/features/farm_log/data/farm_models.dart';

class YieldTrackerScreen extends ConsumerStatefulWidget {
  const YieldTrackerScreen({super.key});

  @override
  ConsumerState<YieldTrackerScreen> createState() => _YieldTrackerScreenState();
}

class _YieldTrackerScreenState extends ConsumerState<YieldTrackerScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Time', 'This Year', 'This Month', 'Custom'];
  DateTimeRange? _customRange;

  /// Entries inside the selected date range (All Time / This Year / This Month / Custom).
  List<YieldEntry> _inRange(List<YieldEntry> all) {
    final now = DateTime.now();
    return all.where((e) {
      switch (_selectedTabIndex) {
        case 1:
          return e.date.year == now.year;
        case 2:
          return e.date.year == now.year && e.date.month == now.month;
        case 3:
          final r = _customRange;
          if (r == null) return true;
          final day = DateTime(e.date.year, e.date.month, e.date.day);
          return !day.isBefore(r.start) && !day.isAfter(r.end);
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now),
    );
    if (picked != null) setState(() { _selectedTabIndex = 3; _customRange = picked; });
  }

  /// Monthly totals for the chart: the last six months that have entries.
  List<MapEntry<DateTime, int>> _monthlyTotals(List<YieldEntry> entries) {
    final totals = <DateTime, int>{};
    for (final e in entries) {
      final m = DateTime(e.date.year, e.date.month);
      totals[m] = (totals[m] ?? 0) + e.yieldAmount;
    }
    final months = totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return months.length > 6 ? months.sublist(months.length - 6) : months;
  }

  /// A harvest belongs to a field, so a farmer with no fields is asked to add one first.
  Future<void> _addHarvest() async {
    List<FieldBlock> fields = ref.read(fieldBlocksProvider).valueOrNull ?? await ref.read(fieldBlocksProvider.future);
    if (!mounted) return;
    if (fields.isEmpty) {
      final added = await showAddFieldSheet(context, ref);
      if (!added || !mounted) return;
      fields = await ref.read(fieldBlocksProvider.future);
      if (!mounted || fields.isEmpty) return;
    }
    await showAddHarvestSheet(context, ref, fields);
  }

  // Colors
  final Color _goldAccent = const Color(0xFFF5C842);
  final Color _darkGreen = const Color(0xFF0F3820);

  @override
  Widget build(BuildContext context) {
    final yieldsAsync = ref.watch(yieldEntriesProvider);

    return Scaffold(
      backgroundColor: _darkGreen,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHarvest,
        backgroundColor: _goldAccent,
        icon: const Icon(Icons.add_rounded, color: Color(0xFF0F3820)),
        label: Text(
          context.tr(en: 'Add Harvest', si: 'අස්වැන්න එක්කරන්න', ta: 'அறுவடை சேர்க்க'),
          style: const TextStyle(color: Color(0xFF0F3820), fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F3820), Color(0xFF05130B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      context.tr(en: 'Yield Tracker', si: 'à¶…à·ƒà·Šà·€à·à¶±à·Šà¶± à¶½à·”à·„à·”à¶¶à·à¶³à·“à¶¸', ta: 'à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯ à®•à®£à¯à®•à®¾à®£à®¿à®ªà¯à®ªà®¾à®³à®°à¯'),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const LanguageSelectorButton(isCompact: true),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date Range Header
                      Text(
                        context.tr(en: 'Date Range', si: 'à¶¯à·’à¶± à¶´à¶»à·à·ƒà¶º', ta: 'à®¤à¯‡à®¤à®¿ à®µà®°à®®à¯à®ªà¯'),
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      
                      // Custom Scrollable Tabs
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tabs.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedTabIndex == index;
                            final tabLabels = [
                              context.tr(en: 'All Time', si: 'à·ƒà·’à¶ºà¶½à·” à¶šà·à¶½', ta: 'à®Žà®²à¯à®²à®¾ à®¨à¯‡à®°à®®à¯à®®à¯'),
                              context.tr(en: 'This Year', si: 'à¶¸à·™à¶¸ à·€à·ƒà¶»à·š', ta: 'à®‡à®¨à¯à®¤ à®†à®£à¯à®Ÿà¯'),
                              context.tr(en: 'This Month', si: 'à¶¸à·™à¶¸ à¶¸à·à·ƒà¶ºà·š', ta: 'à®‡à®¨à¯à®¤ à®®à®¾à®¤à®®à¯'),
                              context.tr(en: 'Custom', si: 'à·€à·™à¶±à¶­à·Š', ta: 'à®¤à®©à®¿à®ªà¯à®ªà®¯à®©à¯'),
                            ];
                            return GestureDetector(
                              onTap: () => index == 3 ? _pickCustomRange() : setState(() => _selectedTabIndex = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? _goldAccent : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(color: _goldAccent.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Text(
                                  tabLabels[index],
                                  style: TextStyle(
                                    color: isSelected ? _darkGreen : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Chart and summary â€” calculated from the farmer's yield entries
                      Builder(builder: (context) {
                        final entries = _inRange(yieldsAsync.valueOrNull ?? const <YieldEntry>[]);
                        final months = _monthlyTotals(entries);
                        final maxMonth = months.isEmpty ? 0 : months.map((m) => m.value).reduce((a, b) => a > b ? a : b);
                        final maxY = maxMonth == 0 ? 100.0 : (maxMonth * 1.2 / 50).ceil() * 50.0;
                        final total = entries.fold<int>(0, (sum, e) => sum + e.yieldAmount);
                        final byCrop = <String, int>{};
                        for (final e in entries) {
                          byCrop[e.cropName] = (byCrop[e.cropName] ?? 0) + e.yieldAmount;
                        }
                        final best = byCrop.entries.isEmpty ? null : (byCrop.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
                        final last = entries.isEmpty ? null : entries.last;
                        final nf = NumberFormat.decimalPattern();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_selectedTabIndex == 3 && _customRange != null) ...[
                              Text(
                                '${DateFormat('d MMM yyyy').format(_customRange!.start)} â€“ ${DateFormat('d MMM yyyy').format(_customRange!.end)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _buildGlassContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(en: 'Yield per Month (kg)', si: 'à¶¸à·à·ƒà·’à¶š à¶…à·ƒà·Šà·€à·à¶±à·Šà¶± (kg)', ta: 'à®®à®¾à®¤à®¾à®¨à¯à®¤à®¿à®° à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯ (kg)'),
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 200,
                                    child: months.isEmpty
                                        ? Center(
                                            child: Text(
                                              context.tr(en: 'No harvests in this period', si: 'à¶¸à·™à¶¸ à¶šà·à¶½à¶ºà·š à¶…à·ƒà·Šà·€à¶±à·” à¶±à·à¶­', ta: 'à®‡à®¨à¯à®¤à®•à¯ à®•à®¾à®²à®¤à¯à®¤à®¿à®²à¯ à®…à®±à¯à®µà®Ÿà¯ˆ à®‡à®²à¯à®²à¯ˆ'),
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                          )
                                        : BarChart(
                                            BarChartData(
                                              alignment: BarChartAlignment.spaceAround,
                                              maxY: maxY,
                                              barTouchData: BarTouchData(
                                                enabled: true,
                                                touchTooltipData: BarTouchTooltipData(
                                                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                                                    '${nf.format(rod.toY.round())} kg',
                                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                              titlesData: FlTitlesData(
                                                show: true,
                                                bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 30,
                                                    getTitlesWidget: (value, meta) {
                                                      final i = value.toInt();
                                                      if (i < 0 || i >= months.length) return const SizedBox.shrink();
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 8.0),
                                                        child: Text(
                                                          DateFormat('MMM').format(months[i].key).toUpperCase(),
                                                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                leftTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 40,
                                                    interval: maxY / 4,
                                                    getTitlesWidget: (value, meta) => Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                                    ),
                                                  ),
                                                ),
                                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              ),
                                              gridData: FlGridData(
                                                show: true,
                                                drawVerticalLine: false,
                                                horizontalInterval: maxY / 4,
                                                getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.1), strokeWidth: 1),
                                              ),
                                              borderData: FlBorderData(show: false),
                                              barGroups: [
                                                for (var i = 0; i < months.length; i++) _buildBarGroup(i, months[i].value.toDouble(), maxY),
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(Icons.shopping_bag_outlined, context.tr(en: 'Total Harvest', si: 'à¶¸à·”à·…à·” à¶…à·ƒà·Šà·€à·à¶±à·Šà¶±', ta: 'à®®à¯Šà®¤à¯à®¤ à®…à®±à¯à®µà®Ÿà¯ˆ'), '${nf.format(total)} kg')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSummaryCard(Icons.emoji_events_outlined, context.tr(en: 'Avg Yield/Crop', si: 'à·ƒà·à¶¸à·à¶±à·Šâ€à¶º à¶…à·ƒà·Šà·€à·à¶±à·Šà¶±', ta: 'à®šà®°à®¾à®šà®°à®¿ à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯'), byCrop.isEmpty ? 'â€”' : '${nf.format((total / byCrop.length).round())} kg')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(Icons.grass_rounded, context.tr(en: 'Best Crop', si: 'à·„à·œà¶³à¶¸ à¶¶à·à¶œà¶º', ta: 'à®šà®¿à®±à®¨à¯à®¤ à®ªà®¯à®¿à®°à¯'), best == null ? 'â€”' : '${context.trCrop(best.key)}\n${nf.format(best.value)} kg')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSummaryCard(Icons.calendar_today_outlined, context.tr(en: 'Last Entry', si: 'à¶…à·€à·ƒà¶±à·Š à·ƒà¶§à·„à¶±', ta: 'à®•à®Ÿà¯ˆà®šà®¿ à®ªà®¤à®¿à®µà¯'), last == null ? 'â€”' : '${DateFormat('MMM d').format(last.date)}\n${nf.format(last.yieldAmount)} kg')),
                              ],
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 32),

                      // Yield Entries List
                      Text(
                        context.tr(en: 'Yield Entries', si: 'à¶…à·ƒà·Šà·€à¶±à·” à·ƒà¶§à·„à¶±à·Š', ta: 'à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯ à®ªà®¤à®¿à®µà¯à®•à®³à¯'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassContainer(
                        padding: const EdgeInsets.all(0),
                        child: yieldsAsync.when(
                          data: (allEntries) {
                            final entries = _inRange(allEntries).reversed.toList();
                            if (entries.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(child: Text(context.tr(en: 'No yield entries in this period.', si: 'à¶¸à·™à¶¸ à¶šà·à¶½à¶ºà·š à¶…à·ƒà·Šà·€à¶±à·” à·ƒà¶§à·„à¶±à·Š à¶±à·à¶­.', ta: 'à®‡à®¨à¯à®¤à®•à¯ à®•à®¾à®²à®¤à¯à®¤à®¿à®²à¯ à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯ à®ªà®¤à®¿à®µà¯à®•à®³à¯ à®‡à®²à¯à®²à¯ˆ.'), style: const TextStyle(color: Colors.white70))),
                              );
                            }
                            return Column(
                              children: [
                                _buildListHeader(),
                                ...entries.asMap().entries.map((e) {
                                  final i = e.key;
                                  final entry = e.value;
                                  final dateStr = DateFormat('MMM dd').format(entry.date);
                                  final isLast = i == entries.length - 1;
                                  
                                  return Column(
                                    children: [
                                      _buildListItem(dateStr, entry.cropName, entry.fieldId, '${entry.yieldAmount} kg', isLast: isLast),
                                      if (!isLast) _buildDivider(),
                                    ],
                                  );
                                }),
                              ],
                            );
                          },
                          loading: () => const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Colors.white))),
                          error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text(context.tr(en: 'Could not load yield entries.', si: 'à¶…à·ƒà·Šà·€à¶±à·” à·ƒà¶§à·„à¶±à·Š à¶´à·–à¶»à¶«à¶º à¶šà·… à¶±à·œà·„à·à¶š.', ta: 'à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯ à®ªà®¤à®¿à®µà¯à®•à®³à¯ˆ à®à®±à¯à®± à®®à¯à®Ÿà®¿à®¯à®µà®¿à®²à¯à®²à¯ˆ.'), style: const TextStyle(color: Colors.redAccent))),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: _goldAccent,
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(IconData icon, String title, String value) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _goldAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _goldAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(context.tr(en: 'Date', si: 'à¶¯à·’à¶±à¶º', ta: 'à®¤à¯‡à®¤à®¿'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(context.tr(en: 'Crop', si: 'à¶¶à·à¶œà¶º', ta: 'à®ªà®¯à®¿à®°à¯'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(context.tr(en: 'Field ID', si: 'à¶šà·Šà·‚à·šà¶­à·Šâ€à¶»à¶º', ta: 'à®¨à®¿à®²à®®à¯'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(context.tr(en: 'Yield', si: 'à¶…à·ƒà·Šà·€à·à¶±à·Šà¶±', ta: 'à®µà®¿à®³à¯ˆà®šà¯à®šà®²à¯'), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildListItem(String date, String crop, String field, String yieldVal, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(flex: 3, child: Text(context.trCrop(crop), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(field, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(flex: 2, child: Text(yieldVal, textAlign: TextAlign.right, style: TextStyle(color: _goldAccent, fontSize: 13, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.white.withValues(alpha: 0.1), indent: 16, endIndent: 16);
}

