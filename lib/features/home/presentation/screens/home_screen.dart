import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/features/weather/presentation/providers/weather_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/camera_capture_screen.dart';
import 'package:plant_disease_detector/features/weather/presentation/screens/weather_forecast_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_catalogue_screen.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/expert_consult_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/community_feed_screen.dart';
import 'package:plant_disease_detector/features/community/presentation/screens/disease_radar_screen.dart';
import 'package:plant_disease_detector/features/tips/presentation/screens/tips_feed_screen.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/diagnosis/application/scan_history_provider.dart';
import 'package:plant_disease_detector/features/diagnosis/presentation/screens/diagnostic_result_screen.dart';
import 'package:plant_disease_detector/features/home/application/saved_items_provider.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/main_screen.dart';
import 'package:plant_disease_detector/features/home/presentation/screens/saved_items_screen.dart';
import 'package:plant_disease_detector/models/disease_result.dart';

// â”€â”€ Ultra Premium Tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _bg = Color(0xFFF4F6F5); // Cool, luxury off-white
const _white = Colors.white;
const _emLight = Color(0xFF1E7045);
const _copper = Color(0xFFC87D55);
const _gold = Color(0xFFE8C97A);
const _textDark = Color(0xFF141F1A);
const _textMute = Color(0xFF6B7D73);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _appear, _pulse, _float;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat(reverse: true);
    
    _fade = CurvedAnimation(parent: _appear, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _appear, curve: Curves.easeOutCubic));
    
    _appear.forward();
  }

  @override
  void dispose() {
    _appear.dispose();
    _pulse.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final wx = ref.watch(weatherProvider);
    final user = ref.watch(userProvider);
    final scansAsync = ref.watch(scanHistoryProvider);
    final scans = scansAsync.value?.take(3).toList() ?? [];
    final l10n = AppLocalizations.of(context);

    final hr = DateTime.now().hour;
    String greet = l10n?.goodEvening ?? 'Good Evening';
    if (hr < 12) { greet = l10n?.goodMorning ?? 'Good Morning'; }
    else if (hr < 17) { greet = l10n?.goodAfternoon ?? 'Good Afternoon'; }

    // Share of the last 10 scanned leaves that were healthy (-1 = no scans yet).
    double health = -1;
    if (scans.isNotEmpty) {
      final recent = scans.take(10).toList();
      final healthy = recent.where((s) => s.severity == 'none' || s.diseaseName.toLowerCase().startsWith('healthy')).length;
      health = healthy / recent.length;
    }

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // â‘  STUNNING HERO WITH GLASS HEALTH CARD
                _HeroSection(user: user, greet: greet, loc: loc, wx: wx, float: _float, health: health, scanCount: scans.length, cropCount: user.primaryCrops.length),
                
                const SizedBox(height: 65), // Spacing for straddling card

                // â‘¢ GLOWING SCAN CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ScanCTA(pulse: _pulse),
                ),
                const SizedBox(height: 32),

                // â‘£ BENTO GRID ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _BentoActions(),
                ),
                const SizedBox(height: 32),

                // â‘¤ RECENT SCANS
                scansAsync.when(
                  data: (data) => _RecentScans(scans: data.take(3).toList()),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: _copper),
                  )),
                  error: (error, stack) => Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(context.tr(en: 'Error loading scans', si: 'à·ƒà·Šà¶šà·‘à¶±à·Š à¶´à·–à¶»à¶«à¶º à¶šà·… à¶±à·œà·„à·à¶š', ta: 'à®¸à¯à®•à¯‡à®©à¯à®•à®³à¯ˆ à®à®±à¯à®± à®®à¯à®Ÿà®¿à®¯à®µà®¿à®²à¯à®²à¯ˆ'), style: TextStyle(color: Colors.red)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â‘  HERO & TRUE GLASS WEATHER CARD
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _HeroSection extends StatelessWidget {
  final dynamic user, greet, loc, wx;
  final AnimationController float;
  final double health;
  final int scanCount, cropCount;

  const _HeroSection({required this.user, required this.greet, required this.loc, required this.wx, required this.float, required this.health, required this.scanCount, required this.cropCount});

  @override
  Widget build(BuildContext context) {
    final temp = wx.isLoading ? '--' : '${wx.weather?.temperature.toStringAsFixed(0) ?? 24}';
    final city = loc.isLoading ? 'Locating...' : loc.address.split(',').first;
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final firstName = user.fullName.split(' ').first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // PREMIUM MESH GREEN BACKGROUND
        Container(
          padding: const EdgeInsets.only(bottom: 50),
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
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            child: Stack(
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
                SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // Floating Glows
                      AnimatedBuilder(
                        animation: float,
                        builder: (_, _child) => Positioned(
                          right: 20, top: 40 + (float.value * 15),
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [_gold.withValues(alpha: 0.2), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
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
                                        TextSpan(text: 'Lumina ', style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                        TextSpan(text: 'Agri AI', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const LanguageSelectorButton(isDark: true, isCompact: true),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => context.push('/notifications'),
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              // Profile Avatar
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _gold.withValues(alpha: 0.8), width: 1.5),
                                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 10)],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: user.imagePath != null
                                      ? SmartImage(src: user.imagePath!, fit: BoxFit.cover, errorWidget: _fallbackAvatar(firstName))
                                      : _fallbackAvatar(firstName),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Premium Typography Greeting - One Line
                      Text(
                        '${greet.replaceAll(',', '')}, $firstName!',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // PREMIUM INLINE WEATHER PILL (Clickable)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherForecastScreen())),
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
                              const Icon(Icons.location_on_rounded, color: _gold, size: 14),
                              const SizedBox(width: 4),
                              Text(city, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 12, color: Colors.white30),
                              const SizedBox(width: 12),
                              Icon(wx.weather?.isDay != false ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, color: wx.weather?.isDay != false ? Colors.orangeAccent : Colors.indigo.shade200, size: 14),
                              const SizedBox(width: 4),
                              Text('$tempÂ°C', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 12, color: Colors.white30),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Space for straddling health card
                    ],
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),

        // GLASSMORPHIC HEALTH CARD (Straddling the Edge)
        Positioned(
          bottom: -45,
          left: 24,
          right: 24,
          child: _HealthCard(health: health, count: scanCount, cropCount: cropCount),
        ),
      ],
    );
  }

  Widget _fallbackAvatar(String name) => Container(
    color: _copper,
    child: Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â‘¡ ULTRA-PREMIUM HEALTH CARD â€” Editorial Light Theme Layout
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _HealthCard extends StatelessWidget {
  final double health;
  final int count;
  final int cropCount;
  const _HealthCard({required this.health, required this.count, required this.cropCount});

  @override
  Widget build(BuildContext context) {
    final noScans = health < 0;
    final pct = noScans ? 0 : (health * 100).round();
    final Color glowC = noScans ? const Color(0xFF9AA79F) : pct >= 80 ? const Color(0xFF238E50)
        : pct >= 60 ? const Color(0xFFF5C842) : const Color(0xFFFF6B6B);
    final String lbl  = noScans ? context.tr(en: 'Scan a leaf to start', si: 'à¶†à¶»à¶¸à·Šà¶· à¶šà·’à¶»à·“à¶¸à¶§ à¶šà·œà·…à¶ºà¶šà·Š à·ƒà·Šà¶šà·‘à¶±à·Š à¶šà¶»à¶±à·Šà¶±', ta: 'à®¤à¯Šà®Ÿà®™à¯à®• à®’à®°à¯ à®‡à®²à¯ˆà®¯à¯ˆ à®¸à¯à®•à¯‡à®©à¯ à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯')
        : pct >= 80 ? context.tr(en: 'Excellent', si: 'à·€à·’à·à·’à·‚à·Šà¶§à¶ºà·’', ta: 'à®šà®¿à®±à®ªà¯à®ªà¯')
        : pct >= 60 ? context.tr(en: 'Moderate', si: 'à¶¸à¶°à·Šâ€à¶ºà¶¸', ta: 'à®¨à®Ÿà¯à®¤à¯à®¤à®°à®®à¯') : context.tr(en: 'At Risk', si: 'à¶…à·€à¶¯à·à¶±à¶¸à·Š', ta: 'à®†à®ªà®¤à¯à®¤à®¿à®²à¯');

    return Container(
      height: 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2A066).withValues(alpha: 0.4), width: 1.2),
            ),
            child: Stack(
              children: [
            // Ambient radial glow behind the big number (soft light)
            Positioned(left: -30, top: -30,
              child: Container(width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    glowC.withValues(alpha: 0.08), Colors.transparent,
                  ]),
                ))),
            // Layout: big number LEFT | hairline | info RIGHT
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left panel: editorial huge score
                SizedBox(
                  width: 112,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(noScans ? 'â€”' : '$pct',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 68,
                            fontWeight: FontWeight.w900, height: 1,
                            letterSpacing: -4,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                          )),
                        Text('%',
                          style: const TextStyle(
                            color: Color(0xFFF5C842),
                            fontSize: 14, fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          )),
                      ],
                    ),
                  ),
                ),
                // Hairline vertical divider
                Container(width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 22),
                    color: Colors.white.withValues(alpha: 0.12)),
                // Right panel: label + status + badges
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr(en: 'FARM HEALTH SCORE', si: 'à¶œà·œà·€à·’à¶´à¶½ à·ƒà·žà¶›à·Šâ€à¶º à¶¯à¶»à·Šà·à¶šà¶º', ta: 'à®ªà®£à¯à®£à¯ˆ à®†à®°à¯‹à®•à¯à®•à®¿à®¯ à®®à®¤à®¿à®ªà¯à®ªà¯†à®£à¯').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF5C842),
                            fontSize: 9.5, fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          )),
                        Row(children: [
                          // Glowing dot indicator
                          Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: glowC, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: glowC.withValues(alpha: 0.4),
                                  blurRadius: 6, spreadRadius: 1)],
                            )),
                          const SizedBox(width: 8),
                          Text(lbl, style: const TextStyle(
                            color: Colors.white, fontSize: 19,
                            fontWeight: FontWeight.w800, letterSpacing: -0.3,
                          )),
                        ]),
                        Row(children: [
                          _Chip(icon: Icons.document_scanner_rounded,
                              text: context.tr(en: '$count Scans', si: 'à·ƒà·Šà¶šà·‘à¶±à·Š $count', ta: '$count à®¸à¯à®•à¯‡à®©à¯à®•à®³à¯')),
                          const SizedBox(width: 8),
                          _Chip(icon: Icons.eco_rounded, text: context.tr(en: '$cropCount Crops', si: 'à·€à¶œà·à·€à¶±à·Š $cropCount', ta: '$cropCount à®ªà®¯à®¿à®°à¯à®•à®³à¯')),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: const Color(0xFFF5C842), size: 12),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(
          color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
    ]),
  );
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â‘¢ REFINED SCAN CTA â€” Light Premium Glow
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScanCTA extends StatelessWidget {
  final Animation<double> pulse;
  const _ScanCTA({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CameraCaptureScreen())),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, child) =>
            Transform.scale(scale: 0.994 + pulse.value * 0.008, child: child),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFF238E50).withValues(alpha: 0.12),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              // Ghost watermark
              Positioned(right: 12, top: 0, bottom: 0,
                child: Icon(Icons.qr_code_scanner_rounded,
                    size: 90, color: const Color(0xFF238E50).withValues(alpha: 0.06)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(children: [
                  // Icon with pulsing border ring
                  AnimatedBuilder(
                    animation: pulse,
                    builder: (_, _child) => Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF238E50).withValues(alpha: 0.15 + pulse.value * 0.1),
                            blurRadius: 16, spreadRadius: pulse.value * 2,
                          )
                        ]
                      ),
                      child: const Icon(Icons.document_scanner_rounded,
                          color: Color(0xFF238E50), size: 24),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.tr(en: 'Scan Your Crop', si: 'à¶”à¶¶à·š à·€à¶œà·à·€ à¶´à¶»à·“à¶šà·Šà·‚à· à¶šà¶»à¶±à·Šà¶±', ta: 'à®‰à®™à¯à®•à®³à¯ à®ªà®¯à®¿à®°à¯ˆ à®¸à¯à®•à¯‡à®©à¯ à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯'),
                          style: const TextStyle(color: Color(0xFF0A1C11), fontSize: 20,
                              fontWeight: FontWeight.w900, letterSpacing: -0.4, height: 1.1)),
                        const SizedBox(height: 5),
                        Text(context.tr(en: 'AI-powered diagnosis in seconds', si: 'à¶­à¶­à·Šà¶´à¶» à¶šà·’à·„à·’à¶´à¶ºà¶šà·’à¶±à·Š AI à¶¸à¶Ÿà·’à¶±à·Š à¶»à·à¶œ à·€à·’à¶±à·’à·à·Šà¶ à¶º', ta: 'à®šà®¿à®² à®µà®¿à®©à®¾à®Ÿà®¿à®•à®³à®¿à®²à¯ AI à®®à¯‚à®²à®®à¯ à®¨à¯‹à®¯à¯ à®•à®£à¯à®Ÿà®±à®¿à®¤à®²à¯'),
                          style: TextStyle(color: const Color(0xFF0A1C11).withValues(alpha: 0.55),
                              fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Circular emerald arrow button
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF238E50), Color(0xFF145730)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF145730).withValues(alpha: 0.40),
                            blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â‘£ LUXURY ACTIONS â€” Unified dark base + colored top accent
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _BentoActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr(en: 'QUICK ACTIONS', si: 'à¶‰à¶šà·Šà¶¸à¶±à·Š à¶šà·Šâ€à¶»à·’à¶ºà·', ta: 'à®µà®¿à®°à¯ˆà®µà®¾à®© à®šà¯†à®¯à®²à¯à®•à®³à¯'),
            style: TextStyle(color: _textMute, fontSize: 10.5,
                fontWeight: FontWeight.w800, letterSpacing: 1.6)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(flex: 5, child: _LuxTile(
            icon: Icons.radar_rounded, label: context.tr(en: 'Disease\nRadar', si: 'à¶»à·à¶œ\nà¶»à·šà¶©à·à¶»à·Š', ta: 'à®¨à¯‹à®¯à¯\nà®°à¯‡à®Ÿà®¾à®°à¯'), sub: context.tr(en: 'Nearby alerts', si: 'à¶…à·€à¶§ à¶…à¶±à¶­à·”à¶»à·” à¶‡à¶Ÿà·€à·“à¶¸à·Š', ta: 'à®…à®°à¯à®•à®¿à®²à¯à®³à¯à®³ à®Žà®šà¯à®šà®°à®¿à®•à¯à®•à¯ˆà®•à®³à¯'),
            accent: const Color(0xFFD4637A),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseRadarScreen())),
          )),
          const SizedBox(width: 13),
          Expanded(flex: 4, child: _LuxTile(
            icon: Icons.support_agent_rounded, label: context.tr(en: 'Expert\nHelp', si: 'à·€à·’à·à·šà·‚à¶¥\nà·ƒà·„à¶º', ta: 'à®¨à®¿à®ªà¯à®£à®°à¯\nà®‰à®¤à®µà®¿'), sub: context.tr(en: 'Ask a pro', si: 'à·€à·’à·à·šà·‚à¶¥à¶ºà·™à¶šà·”à¶œà·™à¶±à·Š à·€à·’à¶¸à·ƒà¶±à·Šà¶±', ta: 'à®’à®°à¯ à®¨à®¿à®ªà¯à®£à®°à®¿à®Ÿà®®à¯ à®•à¯‡à®³à¯à®™à¯à®•à®³à¯'),
            accent: const Color(0xFFD4943A),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertConsultScreen())),
          )),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(flex: 4, child: _LuxTile(
            icon: Icons.menu_book_rounded, label: context.tr(en: 'Disease\nLibrary', si: 'à¶»à·à¶œ\nà¶±à·à¶¸à·à·€à¶½à·’à¶º', ta: 'à®¨à¯‹à®¯à¯\nà®¨à¯‚à®²à®•à®®à¯'), sub: context.tr(en: 'Symptoms & cures', si: 'à¶½à¶šà·Šà·‚à¶« à·ƒà·„ à¶´à·Šâ€à¶»à¶­à·’à¶šà·à¶»', ta: 'à®…à®±à®¿à®•à¯à®±à®¿à®•à®³à¯ & à®šà®¿à®•à®¿à®šà¯à®šà¯ˆ'),
            accent: const Color(0xFF4A86D4),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseCatalogueScreen())),
          )),
          const SizedBox(width: 13),
          Expanded(flex: 5, child: _LuxTile(
            icon: Icons.people_rounded, label: context.tr(en: 'Community\nForum', si: 'à¶´à·Šâ€à¶»à¶¢à·\nà·ƒà¶‚à·ƒà¶¯à¶º', ta: 'à®šà®®à¯‚à®•\nà®®à®©à¯à®±à®®à¯'), sub: context.tr(en: 'Share & learn', si: 'à¶¶à·™à¶¯à·à¶œà¶±à·Šà¶± à·ƒà·„ à¶‰à¶œà·™à¶± à¶œà¶±à·Šà¶±', ta: 'à®ªà®•à®¿à®°à®µà¯à®®à¯ à®•à®±à¯à®•à®µà¯à®®à¯'),
            accent: const Color(0xFF3CAF70),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen())),
          )),
        ]),
        const SizedBox(height: 13),
        _LuxTile(
          icon: Icons.lightbulb_outline_rounded, label: context.tr(en: 'Farming Tips', si: 'à¶œà·œà·€à·’ à¶‹à¶´à¶¯à·™à·ƒà·Š', ta: 'à®µà®¿à®µà®šà®¾à®¯ à®•à¯à®±à®¿à®ªà¯à®ªà¯à®•à®³à¯'), sub: context.tr(en: 'Seasonal advice for your crops', si: 'à¶”à¶¶à·š à¶¶à·à¶œ à·ƒà¶³à·„à· à·ƒà·˜à¶­à·”à¶¸à¶º à¶‹à¶´à¶¯à·™à·ƒà·Š', ta: 'à®‰à®™à¯à®•à®³à¯ à®ªà®¯à®¿à®°à¯à®•à®³à¯à®•à¯à®•à®¾à®© à®ªà®°à¯à®µà®•à®¾à®² à®†à®²à¯‹à®šà®©à¯ˆ'),
          accent: const Color(0xFF8A6FD4),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TipsFeedScreen())),
        ),
      ],
    );
  }
}

class _LuxTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color accent;
  final VoidCallback onTap;
  const _LuxTile({
    required this.icon, required this.label, required this.sub,
    required this.accent, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          // Pristine white tile
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: const Color(0xFF042211).withValues(alpha: 0.04),
                blurRadius: 24, offset: const Offset(0, 10)),
            // Faint colored shadow for that Apple-like glow
            BoxShadow(color: accent.withValues(alpha: 0.08),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ghost icon watermark â€” right side
              Positioned(right: -10, bottom: -10,
                  child: Icon(icon, size: 75,
                      color: accent.withValues(alpha: 0.04))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon chip with colored background
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    // Text block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF0A1C11),
                              fontSize: 12, fontWeight: FontWeight.w800,
                              height: 1.25, letterSpacing: 0.1)),
                        const SizedBox(height: 3),
                        Text(sub, maxLines: 1,
                          style: TextStyle(color: const Color(0xFF0A1C11).withValues(alpha: 0.45),
                              fontSize: 9.5, fontWeight: FontWeight.w600,
                              letterSpacing: 0.2)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// â‘¤ RECENT SCANS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _RecentScans extends StatelessWidget {
  final List<dynamic> scans;
  const _RecentScans({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr(en: 'RECENT SCANS', si: 'à¶¸à·‘à¶­à¶šà·à¶½à·“à¶± à·ƒà·Šà¶šà·‘à¶±à·Š', ta: 'à®šà®®à¯€à®ªà®¤à¯à®¤à®¿à®¯ à®¸à¯à®•à¯‡à®©à¯à®•à®³à¯'), style: const TextStyle(color: _textMute, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              GestureDetector(
                onTap: () => ProviderScope.containerOf(context).read(mainTabProvider.notifier).state = 2,
                child: Text(context.tr(en: 'See All', si: 'à·ƒà·’à¶ºà¶½à·Šà¶½ à¶¶à¶½à¶±à·Šà¶±', ta: 'à®…à®©à¯ˆà®¤à¯à®¤à¯ˆà®¯à¯à®®à¯ à®•à®¾à®£à¯à®•'), style: const TextStyle(color: _copper, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (scans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(24)),
              child: Center(child: Text(context.tr(en: 'No recent scans found.', si: 'à¶¸à·‘à¶­à¶šà·à¶½à·“à¶± à·ƒà·Šà¶šà·‘à¶±à·Š à·„à¶¸à·”à·€à·–à¶ºà·š à¶±à·à¶­.', ta: 'à®šà®®à¯€à®ªà®¤à¯à®¤à®¿à®¯ à®¸à¯à®•à¯‡à®©à¯à®•à®³à¯ à®Žà®¤à¯à®µà¯à®®à¯ à®•à®¾à®£à®ªà¯à®ªà®Ÿà®µà®¿à®²à¯à®²à¯ˆ.'), style: const TextStyle(color: _textMute))),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: scans.length,
              itemBuilder: (ctx, i) {
                final s = scans[i];
                return Padding(
                  padding: EdgeInsets.only(right: i < scans.length - 1 ? 20 : 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => DiagnosticResultScreen(scan: s))),
                    child: _ScanCard(scan: s),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  final dynamic scan;
  const _ScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final pct = (scan.confidenceScore * 100).round();
    final c = pct >= 80 ? const Color(0xFF27AE60) : pct >= 60 ? const Color(0xFFF2994A) : const Color(0xFFEB5757);
    
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 120, width: double.infinity,
                child: SmartImage(src: scan.imageUrl, fit: BoxFit.cover),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('$pct%', style: const TextStyle(color: _textDark, fontSize: 12, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8, left: 8,
                child: _BookmarkButton(scan: scan as ScanRecord),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.trDisease(scan.diseaseName),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(context.trDate(scan.dateLabel),
                    style: const TextStyle(color: _textMute, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Saved Items â€” Create (save) and Delete (unsave) straight from a recent scan.
class _BookmarkButton extends ConsumerStatefulWidget {
  final ScanRecord scan;
  const _BookmarkButton({required this.scan});

  @override
  ConsumerState<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<_BookmarkButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final notifier = ref.read(savedItemsProvider.notifier);
    final existing = notifier.itemForScan(widget.scan.id);
    final messenger = ScaffoldMessenger.of(context);
    final savedText = context.tr(en: 'Saved to Saved Items', si: 'à·ƒà·”à¶»à·à¶šà·’ à¶…à¶ºà·’à¶­à¶¸ à·€à¶½à¶§ à·ƒà·”à¶»à·à¶šà·”à¶«à·', ta: 'à®šà¯‡à®®à®¿à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿà®µà¯ˆà®¯à®¿à®²à¯ à®šà¯‡à®°à¯à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿà®¤à¯');
    final removedText = context.tr(en: 'Removed from saved items', si: 'à·ƒà·”à¶»à·à¶šà·’ à¶…à¶ºà·’à¶­à¶¸ à·€à¶½à·’à¶±à·Š à¶‰à·€à¶­à·Š à¶šà·…à·', ta: 'à®šà¯‡à®®à®¿à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿà®µà¯ˆà®¯à®¿à®²à®¿à®°à¯à®¨à¯à®¤à¯ à®¨à¯€à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿà®¤à¯');
    final viewText = context.tr(en: 'View', si: 'à¶¶à¶½à¶±à·Šà¶±', ta: 'à®ªà®¾à®°à¯');
    final errorText = context.tr(en: 'Something went wrong. Please try again.', si: 'à¶ºà¶¸à¶šà·Š à·€à·à¶»à¶¯à·”à¶«à·. à¶±à·à·€à¶­ à¶‹à¶­à·Šà·ƒà·à·„ à¶šà¶»à¶±à·Šà¶±.', ta: 'à®à®¤à¯‹ à®¤à®µà®±à¯ à®¨à®Ÿà®¨à¯à®¤à®¤à¯. à®®à¯€à®£à¯à®Ÿà¯à®®à¯ à®®à¯à®¯à®±à¯à®šà®¿à®•à¯à®•à®µà¯à®®à¯.');

    setState(() => _busy = true);
    try {
      if (existing == null) {
        await notifier.saveScan(widget.scan);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
          content: Text(savedText),
          backgroundColor: _emLight,
          action: SnackBarAction(
            label: viewText,
            textColor: _gold,
            onPressed: () {
              if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsScreen()));
            },
          ),
        ));
      } else {
        await notifier.remove(existing.id);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(removedText)));
      }
    } catch (_) {
      // e.g. saved from another device meanwhile â€” resync with the database.
      ref.invalidate(savedItemsProvider);
      messenger.showSnackBar(SnackBar(content: Text(errorText), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedItemsProvider).maybeWhen(
          data: (items) => items.any((item) => item.scanId == widget.scan.id),
          orElse: () => false,
        );

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: _white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: _busy
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(strokeWidth: 2, color: _emLight),
              )
            : Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? _emLight : _textMute,
                size: 20,
              ),
      ),
    );
  }
}

