import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/models/agri_officer.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';

class NearestOfficerScreen extends ConsumerStatefulWidget {
  const NearestOfficerScreen({super.key});

  @override
  ConsumerState<NearestOfficerScreen> createState() => _NearestOfficerScreenState();
}

class _NearestOfficerScreenState extends ConsumerState<NearestOfficerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label action triggered'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final officer = getNearestOfficer(locationState.address);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Hero background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SmartImage(
                    src: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&fit=crop&auto=format',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.officerOverlay,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${officer.distanceKm} ${context.tr(en: 'km away', si: 'කි.මී. දුරින්', ta: 'கி.மீ தொலைவில்')}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Officer hero card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            officer.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.secondary,
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(officer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(officer.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppColors.callAction, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr(en: 'Available Now', si: 'දැන් සම්බන්ධ විය හැක', ta: 'இப்போது தொடர்பு கொள்ளலாம்'),
                                  style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Scrollable content
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_slideAnim),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.officerCardBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Actions
                            Row(
                              children: [
                                _buildActionButton(Icons.phone_rounded, context.tr(en: 'Call', si: 'ඇමතුම්', ta: 'அழைப்பு'), AppColors.callAction),
                                const SizedBox(width: 12),
                                _buildActionButton(Icons.chat_bubble_rounded, 'WhatsApp', AppColors.whatsapp),
                                const SizedBox(width: 12),
                                _buildActionButton(Icons.email_rounded, context.tr(en: 'Email', si: 'විද්‍යුත් තැපෑල', ta: 'மின்னஞ்சல்'), AppColors.primary),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Info card
                            _buildInfoCard(officer),

                            const SizedBox(height: 20),

                            // Specializations
                            Text(context.tr(en: 'Specializations', si: 'විශේෂඥ ක්ෂේත්‍ර', ta: 'நிபுணத்துவம்'), style: AppTextStyles.titleSmall),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: officer.specializations.map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                                ),
                                child: Text(s, style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12)),
                              )).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Map placeholder
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      'https://images.unsplash.com/photo-1604537372136-89b3dae196e3?w=800&fit=crop&auto=format',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.secondary.withValues(alpha: 0.2),
                                        child: const Center(child: Icon(Icons.map_rounded, size: 48, color: AppColors.secondary)),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(50),
                                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(officer.center, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Primary CTA
                            GestureDetector(
                              onTap: () => _onAction('Call'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${context.tr(en: 'Call', si: 'අමතන්න', ta: 'அழைக்கவும்')} ${officer.name.split(' ').first} ${context.tr(en: 'Now', si: 'දැන්', ta: 'இப்போது')}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onAction(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AgriOfficer officer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_city_rounded, context.tr(en: 'Service Center', si: 'සේවා මධ්‍යස්ථානය', ta: 'சேவை மையம்'), officer.center),
          const Divider(height: 24, color: AppColors.dividerSubtle),
          _buildInfoRow(Icons.location_on_rounded, context.tr(en: 'Zone', si: 'කලාපය', ta: 'வலயம்'), officer.zone),
          const Divider(height: 24, color: AppColors.dividerSubtle),
          _buildInfoRow(Icons.schedule_rounded, context.tr(en: 'Availability', si: 'ලබාගත හැකි වේලාව', ta: 'இருக்கும் நேரம்'), officer.availability),
          const Divider(height: 24, color: AppColors.dividerSubtle),
          _buildInfoRow(Icons.phone_rounded, context.tr(en: 'Phone', si: 'දුරකථනය', ta: 'தொலைபேசி'), officer.phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
              Text(val, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
