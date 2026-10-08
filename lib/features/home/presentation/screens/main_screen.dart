import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/home_screen.dart';
import 'package:plant_disease_detector/features/history/presentation/screens/history_screen.dart';
import 'package:plant_disease_detector/features/farm_log/presentation/screens/farm_screen.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/profile_screen.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/providers/connectivity_provider.dart';
import 'package:plant_disease_detector/core/providers/database_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/features/sync/presentation/screens/sync_status_screen.dart';

/// Selected bottom tab (0 Home, 1 Farm, 2 History, 3 Profile). Other screens
/// can switch tabs, e.g. Home → Recent Scans → See All opens History.
final mainTabProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// MainScreen — Handles Bottom Navigation (Glassmorphism)
// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Upload any scans saved while offline (e.g. from a previous session).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNow());
  }

  Future<void> _syncNow() async {
    await ref.read(outboxProcessorProvider).processOutbox();
    if (mounted) ref.invalidate(scanHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    // When the connection comes back, upload what was saved offline.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) _syncNow();
    });
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    final pendingCount = ref.watch(pendingUploadsProvider).valueOrNull?.length ?? 0;
    final currentLocale = ref.watch(localeProvider);
    final currentIndex = ref.watch(mainTabProvider);
    final List<Widget> pages = [
      HomeScreen(key: ValueKey('home_tab_${currentLocale.languageCode}')),
      FarmScreen(key: ValueKey('farm_tab_${currentLocale.languageCode}')),
      HistoryScreen(key: ValueKey('history_tab_${currentLocale.languageCode}')),
      ProfileScreen(key: ValueKey('profile_tab_${currentLocale.languageCode}')),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // The active page
          IndexedStack(
            index: currentIndex,
            children: pages,
          ),

          // Offline / waiting-to-upload notice (tap for details)
          if (!online || pendingCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 112, // just above the bottom navigation bar
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncStatusScreen())),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: online ? const Color(0xFFB7791F) : const Color(0xFF37474F),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Icon(online ? Icons.cloud_upload_rounded : Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !online
                                ? context.tr(
                                    en: pendingCount > 0 ? 'Offline · $pendingCount scan(s) will upload later' : 'Offline · scanning still works',
                                    si: pendingCount > 0 ? 'නොබැඳි · ස්කෑන් $pendingCount ක් පසුව උඩුගත වේ' : 'නොබැඳි · ස්කෑන් කිරීම තවමත් ක්‍රියා කරයි',
                                    ta: pendingCount > 0 ? 'ஆஃப்லைன் · $pendingCount ஸ்கேன் பின்னர் பதிவேற்றப்படும்' : 'ஆஃப்லைன் · ஸ்கேன் இன்னும் வேலை செய்யும்',
                                  )
                                : context.tr(
                                    en: '$pendingCount scan(s) waiting to upload',
                                    si: 'ස්කෑන් $pendingCount ක් උඩුගත කිරීමට ඇත',
                                    ta: '$pendingCount ஸ்கேன் பதிவேற்றக் காத்திருக்கிறது',
                                  ),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // ── LIGHT PREMIUM GLASSMORPHIC NAV BAR ──
          Positioned(
            left: 24, right: 24, bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFF7EBE6).withOpacity(0.5), // Earthy warm tint
                    Colors.white.withOpacity(0.4),
                    const Color(0xFFF7EBE6).withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF301608).withOpacity(0.06), // Warm shadow
                    blurRadius: 30, offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_rounded,      context.tr(en: 'Home',    si: 'මුල් පිටුව', ta: 'முகப்பு')),
                        _buildNavItem(1, Icons.grid_view_rounded, context.tr(en: 'Farm',    si: 'ගොවිපළ',    ta: 'பண்ணை')),
                        const SizedBox(width: 58),
                        _buildNavItem(2, Icons.history_rounded,   context.tr(en: 'History', si: 'ඉතිහාසය',   ta: 'வரலாறு')),
                        _buildNavItem(3, Icons.person_rounded,    context.tr(en: 'Profile', si: 'පැතිකඩ',    ta: 'சுயவிவரம்')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── PREMIUM LIGHT FAB ──
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA5A31).withOpacity(0.25), // Terracotta glow
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD9734E), Color(0xFF9C4927)], // Terracotta gradient
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(en: 'SCAN', si: 'ස්කෑන්', ta: 'ஸ்கேன்'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8, fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = ref.watch(mainTabProvider) == index;
    // Elegant light theme nav colors with Earthy Terracotta
    const Color activeColor = Color(0xFFBA5A31);   // Rich terracotta
    const Color inactiveColor = Color(0xFF9BA6AE); // Soft premium silver/grey
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(mainTabProvider.notifier).state = index,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
