import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/providers/locale_provider.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/features/officer/presentation/screens/case_inbox_screen.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/features/officer/data/visit_repository.dart';
import 'package:plant_disease_detector/features/officer/presentation/widgets/scheduled_visits_section.dart';
import 'package:plant_disease_detector/features/profile/presentation/screens/profile_screen.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
// ─────────────────────────────────────────────────────────────────────────────
// OfficerDashboardScreen — Handles Bottom Navigation & Core Views (Premium UI)
// ─────────────────────────────────────────────────────────────────────────────
class OfficerDashboardScreen extends ConsumerStatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  ConsumerState<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends ConsumerState<OfficerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final List<Widget> pages = [
      _OfficerHomeTab(key: ValueKey('officer_home_${currentLocale.languageCode}')),
      CaseInboxScreen(key: ValueKey('officer_inbox_${currentLocale.languageCode}')),
      ProfileScreen(key: ValueKey('officer_profile_${currentLocale.languageCode}')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background blobs for glassmorphism effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F766E).withValues(alpha: 0.25), // Premium Teal
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD9734E).withValues(alpha: 0.15), // Terracotta
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),

          // The active page
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          
          // ── PREMIUM GLASSMORPHIC NAV BAR ──
          Positioned(
            left: 24, right: 24, bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    const Color(0xFFE2E8F0).withValues(alpha: 0.5), 
                    Colors.white.withValues(alpha: 0.4),
                    const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.08), 
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
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.dashboard_rounded, context.tr(en: 'Dashboard', si: 'උපකරණ පුවරුව', ta: 'முகப்பு')),
                        _buildNavItem(1, Icons.inbox_rounded,     context.tr(en: 'Inbox',     si: 'ලිපිගොනු',      ta: 'பெட்டி')),
                        _buildNavItem(2, Icons.person_rounded,    context.tr(en: 'Profile',   si: 'පැතිකඩ',      ta: 'சுயவிவரம்')),
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
    final isSelected = _currentIndex == index;
    const Color activeColor = Color(0xFF0F766E);   // Deep premium teal
    const Color inactiveColor = Color(0xFF9BA6AE); 
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 8 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: isSelected ? 26 : 24,
                ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OfficerHomeTab — The main analytics view (Real Supabase data)
// CRUD: Read (stats, urgent cases, visits) · Update (on-duty status, visits)
//       · Create / Delete (visits, see ScheduledVisitsSection)
// ─────────────────────────────────────────────────────────────────────────────
class _OfficerHomeTab extends ConsumerWidget {
  const _OfficerHomeTab({super.key});

  // ── Update: persist Online / Offline to profiles.is_on_duty ──────────────
  Future<void> _toggleStatus(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(onDutyProvider.notifier).toggle();
      final onDuty = ref.read(onDutyProvider).valueOrNull ?? true;
      messenger.showSnackBar(SnackBar(
        content: Text(onDuty
            ? 'You are Online — new cases can be assigned to you.'
            : 'You are Offline — your status has been saved.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F766E),
      ));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Status could not be saved. Check your connection.'),
        backgroundColor: Color(0xFFEF4444),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real stats from Supabase
    final statsAsync = ref.watch(officerStatsProvider);
    final isOnline = ref.watch(onDutyProvider).valueOrNull ?? true;
    final loc = ref.watch(locationProvider);
    final wx = ref.watch(weatherProvider);
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context);
    
    // Notice: Removed SafeArea so the header can go edge-to-edge
    return Column(
      children: [
        _buildHeroSection(context, loc, wx, user, l10n, isOnline, () => _toggleStatus(context, ref)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(en: 'Analytics Overview', si: 'විශ්ලේෂණ දළ විශ්ලේෂණය', ta: 'பகுப்பாய்வு'), 
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                statsAsync.when(
                  loading: () => _buildAnalyticsCards(context, ref, 0, 0, 0),
                  error: (_, __) => _buildAnalyticsCards(context, ref, 0, 0, 0),
                  data: (stats) => _buildAnalyticsCards(
                    context, ref,
                    stats['pending'] ?? 0,
                    stats['resolvedToday'] ?? 0,
                    stats['urgent'] ?? 0,
                  ),
                ),
                const SizedBox(height: 36),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr(en: 'Urgent Alerts', si: 'හදිසි අනතුරු ඇඟවීම්', ta: 'அவசர எச்சரிக்கைகள்'), 
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => context.push('/case_inbox'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9734E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr(en: 'View All', si: 'සියල්ල පෙන්වන්න', ta: 'அனைத்தையும் காண்க'),
                          style: AppTextStyles.titleSmall.copyWith(color: const Color(0xFFD9734E), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildUrgentAlertsList(context),
                const SizedBox(height: 36),
                const ScheduledVisitsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, dynamic loc, dynamic wx, dynamic user,
      AppLocalizations? l10n, bool isOnline, VoidCallback onToggleStatus) {
    final hr = DateTime.now().hour;
    String greet = l10n?.goodEvening ?? 'Good Evening';
    if (hr < 12) greet = l10n?.goodMorning ?? 'Good Morning';
    else if (hr < 17) greet = l10n?.goodAfternoon ?? 'Good Afternoon';

    final temp = wx.isLoading ? '--' : '${wx.weather?.temperature.toStringAsFixed(0) ?? 24}';
    final city = loc.isLoading ? 'Locating...' : (loc.address.isNotEmpty ? loc.address.split(',').first : 'Unknown');
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final firstName = user.fullName.isNotEmpty ? user.fullName.split(' ').first : 'Officer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 12, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3820), Color(0xFF16502D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Abstract Mesh Shapes
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF2E8B57).withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFF5C842).withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/logo.png', width: 24, height: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: const TextSpan(
                              children: [
                                TextSpan(text: 'Lumina ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                TextSpan(text: 'Officer', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const LanguageSelectorButton(isCompact: true),
                      const SizedBox(width: 12),
                      // Profile Avatar
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8C97A).withValues(alpha: 0.8), width: 1.5),
                          boxShadow: [BoxShadow(color: const Color(0xFFE8C97A).withValues(alpha: 0.3), blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: user.imagePath != null && user.imagePath!.isNotEmpty
                              ? Image.network(user.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackAvatar(firstName))
                              : _fallbackAvatar(firstName),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Premium Typography Greeting
              Text(
                '${greet.replaceAll(',', '')}, $firstName!',
                style: const TextStyle(
                  color: Color(0xFFE8C97A),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                ),
              ),
              const SizedBox(height: 12),
              
              // PREMIUM INLINE WEATHER PILL & STATUS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFF5C842).withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 1)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFE8C97A), size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(city, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 12, color: Colors.white30),
                          const SizedBox(width: 10),
                          Icon(wx.weather?.isDay != false ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, color: wx.weather?.isDay != false ? Colors.orangeAccent : Colors.indigo.shade200, size: 14),
                          const SizedBox(width: 4),
                          Text('$temp°C', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 12, color: Colors.white30),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusToggle(isOnline, onToggleStatus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF134D2E),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'O',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildStatusToggle(bool isOnline, VoidCallback onToggleStatus) {
    return GestureDetector(
      onTap: onToggleStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOnline 
              ? const Color(0xFF22C55E).withValues(alpha: 0.15) 
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOnline ? const Color(0xFF22C55E).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3), 
            width: 1.5
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? const Color(0xFF22C55E) : Colors.grey.shade400,
                boxShadow: isOnline ? [
                  BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)
                ] : [],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800, 
                color: isOnline ? const Color(0xFF22C55E) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(BuildContext context, WidgetRef ref, int pending, int resolvedToday, int urgent) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            context: context,
            title: context.tr(en: 'Pending\nCases', si: 'පොරොත්තු\nනඩු', ta: 'நிலுவையில் உள்ளவை'),
            value: pending.toString(),
            icon: Icons.pending_actions_rounded,
            gradientColors: [const Color(0xFF0F766E), const Color(0xFF042F2E)],
            height: 256,
            onTap: () => context.push('/case_inbox'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildGlassCard(
                context: context,
                title: context.tr(en: 'Resolved Today', si: 'අද විසඳූ', ta: 'இன்று தீர்க்கப்பட்டவை'),
                value: resolvedToday.toString(),
                icon: Icons.check_circle_outline_rounded,
                gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
                height: 120,
                isSmall: true,
                onTap: () => context.push('/case_inbox'),
              ),
              const SizedBox(height: 16),
              _buildGlassCard(
                context: context,
                title: context.tr(en: 'High Priority', si: 'ඉහළ ප්‍රමුඛතා', ta: 'அதிக முன்னுரிமை'),
                value: urgent.toString(),
                icon: Icons.warning_amber_rounded,
                gradientColors: [const Color(0xFFF59E0B), const Color(0xFFB45309)],
                height: 120,
                isSmall: true,
                onTap: () => context.push('/case_inbox'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required double height,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha: 0.85),
            gradientColors[1].withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 0,
            spreadRadius: 1,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 32),
                    ),
                    if (!isSmall)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: isSmall ? 24 : 42, 
                      color: Colors.white, 
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    )),
                    const SizedBox(height: 2),
                    Text(title, style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9), 
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 13 : 16,
                      height: 1.2,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentAlertsList(BuildContext context) {
    // Use the urgentAsync from the parent ConsumerWidget
    final urgentAsync = consultationsProvider(null);
    
    return Consumer(
      builder: (context, ref, _) {
        final asyncData = ref.watch(urgentAsync);
        return asyncData.when(
          loading: () => SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => Container(
                width: 280, height: 170,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox(height: 170,
            child: Center(child: Text('Failed to load alerts'))),
          data: (consultations) {
            final urgent = consultations.where((c) => c.isUrgent && !c.isClosed).toList();
            if (urgent.isEmpty) {
              return Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981), size: 36),
                      const SizedBox(height: 8),
                      Text('No Urgent Alerts',
                          style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: urgent.length,
                clipBehavior: Clip.none,
                itemBuilder: (context, index) {
                  final c = urgent[index];
                  return GestureDetector(
                    onTap: () => context.push('/case_detail', extra: c),
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                            blurRadius: 24, offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emergency_rounded,
                                        color: Color(0xFFDC2626), size: 14),
                                    const SizedBox(width: 4),
                                    Text('URGENT',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: const Color(0xFFDC2626),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(c.timeAgo,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            c.diseaseName ?? 'Unknown Disease',
                            style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${c.location ?? 'Unknown'} • ${c.farmerName ?? 'Farmer'}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
