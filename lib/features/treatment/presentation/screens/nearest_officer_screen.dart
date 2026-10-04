import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/features/officer/data/visit_repository.dart';
import 'package:plant_disease_detector/models/agri_officer.dart';
import 'package:plant_disease_detector/models/officer_visit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _onDutyColor = Color(0xFF10B981);
const _sriLankaCenter = LatLng(7.8731, 80.7718);

// ─────────────────────────────────────────────────────────────────────────────
// NearestOfficerScreen — Officer Location Map.
// CRUD: Read (officers on the map, my visit requests) · Create (request a
//       field visit) · Delete (withdraw a request not yet accepted)
// Requests appear on the AO Dashboard under Scheduled Visits.
// ─────────────────────────────────────────────────────────────────────────────
class NearestOfficerScreen extends ConsumerStatefulWidget {
  const NearestOfficerScreen({super.key});

  @override
  ConsumerState<NearestOfficerScreen> createState() => _NearestOfficerScreenState();
}

class _NearestOfficerScreenState extends ConsumerState<NearestOfficerScreen> {
  final _mapController = MapController();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // The app-wide position is read once at start-up; refresh it so
    // "nearest officer" reflects where the farmer is now.
    Future.microtask(() => ref.read(locationProvider.notifier).fetchLocation());
  }

  /// User position, ignored when outside Sri Lanka (e.g. emulator default),
  /// where "nearest" and km distances would be meaningless.
  LatLng? _userLatLng(LocationState loc) {
    final p = loc.position;
    if (p == null) return null;
    final ll = LatLng(p.latitude, p.longitude);
    return const Distance().as(LengthUnit.Kilometer, ll, _sriLankaCenter) > 400 ? null : ll;
  }

  double? _distanceKm(LatLng? user, AgriOfficer o) {
    final at = o.location;
    if (user == null || at == null) return null;
    return const Distance().as(LengthUnit.Meter, user, at) / 1000;
  }

  List<AgriOfficer> _sortedByDistance(List<AgriOfficer> officers, LatLng? user) {
    final mapped = officers.where((o) => o.location != null).toList();
    if (user == null) return mapped;
    mapped.sort((a, b) => _distanceKm(user, a)!.compareTo(_distanceKm(user, b)!));
    return mapped;
  }

  void _select(AgriOfficer o) {
    setState(() => _selectedId = o.id);
    _mapController.move(o.location!, 10);
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? const Color(0xFFEF4444) : AppColors.primary,
    ));
  }

  Future<void> _call(AgriOfficer o) async {
    final uri = Uri(scheme: 'tel', path: o.phone.replaceAll(' ', ''));
    final opened = await launchUrl(uri);
    if (!opened) _snack('Could not open the phone dialer. Call ${o.phone}.', isError: true);
  }

  Future<void> _requestVisit(AgriOfficer o) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestVisitSheet(officer: o),
    );
    if (sent == true) {
      _snack('Visit request sent to ${o.name}. You will see the date here once an officer schedules it.');
    }
  }

  Future<void> _cancelRequest(OfficerVisit v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdraw this request?'),
        content: const Text('The officer will no longer see it. You can send a new request at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep request')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(visitRepositoryProvider).cancelRequest(v.id);
      // Realtime does not deliver DELETE events on a filtered stream, so
      // re-subscribe to drop the withdrawn row from the list.
      ref.invalidate(myVisitRequestsProvider);
      _snack('Visit request withdrawn.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(agriOfficersProvider);
    final user = _userLatLng(ref.watch(locationProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: officersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => _buildCentered(
          Icons.wifi_off_rounded,
          'Could not load officers.',
          action: TextButton(
            onPressed: () => ref.invalidate(agriOfficersProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (all) {
          final officers = _sortedByDistance(all, user);
          if (officers.isEmpty) {
            return _buildCentered(Icons.person_search_rounded, 'No agricultural officers found.');
          }
          final selected = officers.firstWhere((o) => o.id == _selectedId, orElse: () => officers.first);
          return Column(
            children: [
              Expanded(flex: 5, child: _buildMap(officers, selected, user)),
              Expanded(flex: 6, child: _buildPanel(officers, selected, user)),
            ],
          );
        },
      ),
    );
  }

  // ── Read: officers as pins ───────────────────────────────────────────────
  Widget _buildMap(List<AgriOfficer> officers, AgriOfficer selected, LatLng? user) {
    final points = [for (final o in officers) o.location!, ?user];
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(48, 110, 48, 48))
                : null,
            initialCenter: points.length == 1 ? points.first : _sriLankaCenter,
            initialZoom: 8,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.plantdetector.plant_disease_detector',
            ),
            MarkerLayer(
              markers: [
                if (user != null)
                  Marker(
                    point: user,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                    ),
                  ),
                for (final o in officers)
                  Marker(
                    point: o.location!,
                    width: 52,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _select(o),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: o.id == selected.id ? 52 : 40,
                        color: o.id == selected.id
                            ? AppColors.primary
                            : (o.isOnDuty ? _onDutyColor : Colors.grey.shade600),
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
        // Top bar over the map
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _mapButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: _floatingDecoration(),
                    child: Text(
                      context.tr(en: 'Agricultural Officers', si: 'කෘෂිකර්ම නිලධාරීන්', ta: 'வேளாண் அலுவலர்கள்'),
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: _floatingDecoration(),
                  child: const LanguageSelectorButton(isCompact: true),
                ),
              ],
            ),
          ),
        ),
        if (user != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: _mapButton(Icons.my_location_rounded, () => _mapController.move(user, 10)),
          ),
      ],
    );
  }

  Widget _buildPanel(List<AgriOfficer> officers, AgriOfficer selected, LatLng? user) {
    final distance = _distanceKm(user, selected);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.officerCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildSelectedCard(selected, distance, isNearest: user != null && selected.id == officers.first.id),
          const SizedBox(height: 20),
          Text(context.tr(en: 'All Officers', si: 'සියලු නිලධාරීන්', ta: 'அனைத்து அலுவலர்கள்'),
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: officers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildOfficerChip(officers[i], user, officers[i].id == selected.id),
            ),
          ),
          const SizedBox(height: 24),
          Text(context.tr(en: 'My Visit Requests', si: 'මගේ සංචාර ඉල්ලීම්', ta: 'எனது வருகை கோரிக்கைகள்'),
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          _buildMyRequests(officers),
        ],
      ),
    );
  }

  Widget _buildSelectedCard(AgriOfficer o, double? distance, {required bool isNearest}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  o.initial,
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNearest)
                      Text('NEAREST TO YOU',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Text(o.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                    Text(o.title, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              _statusChip(o),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.location_city_rounded, o.center),
          _infoRow(Icons.phone_rounded, o.phone),
          if (distance != null) _infoRow(Icons.near_me_rounded, '${distance.toStringAsFixed(1)} km away'),
          if (o.specializations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: o.specializations
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _call(o),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.callAction,
                    side: const BorderSide(color: AppColors.callAction, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(context.tr(en: 'Call', si: 'අමතන්න', ta: 'அழைக்கவும்')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _requestVisit(o),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(context.tr(en: 'Request Visit', si: 'සංචාරයක් ඉල්ලන්න', ta: 'வருகை கோருக')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerChip(AgriOfficer o, LatLng? user, bool isSelected) {
    final distance = _distanceKm(user, o);
    return GestureDetector(
      onTap: () => _select(o),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: o.isOnDuty ? _onDutyColor : Colors.grey),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.name.replaceFirst('Ofcr. ', ''),
                    style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700)),
                Text(distance != null ? '${o.zone} • ${distance.toStringAsFixed(0)} km' : o.zone,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Read / Delete: the farmer's own requests ─────────────────────────────
  Widget _buildMyRequests(List<AgriOfficer> officers) {
    final requestsAsync = ref.watch(myVisitRequestsProvider);
    return requestsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => _messageCard(Icons.error_outline_rounded, 'Could not load your requests.'),
      data: (requests) {
        if (requests.isEmpty) {
          return _messageCard(
            Icons.event_note_rounded,
            'No visit requests yet. Pick an officer and tap Request Visit to have them inspect your field.',
          );
        }
        return Column(
          children: requests.map((v) {
            final officer = officers.where((o) => o.id == v.agriOfficerId).firstOrNull;
            return _buildRequestTile(v, officer);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRequestTile(OfficerVisit v, AgriOfficer? officer) {
    final fmt = DateFormat('EEE d MMM, h:mm a');
    final (label, color, detail) = switch (v.status) {
      'scheduled' => (
          'Scheduled',
          AppColors.primary,
          v.scheduledFor != null ? 'Officer visiting ${fmt.format(v.scheduledFor!)}' : 'Officer will visit soon',
        ),
      'completed' => ('Completed', Colors.grey.shade600, 'Visit done'),
      'cancelled' => ('Cancelled', const Color(0xFFDC2626), 'The officer cancelled this visit'),
      _ => (
          'Waiting',
          const Color(0xFFB45309),
          v.scheduledFor != null
              ? 'Preferred: ${DateFormat('EEE d MMM').format(v.scheduledFor!)}'
              : 'Waiting for an officer to schedule',
        ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.agriculture_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(officer?.name ?? 'Agricultural officer',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                if (v.reason != null && v.reason!.isNotEmpty)
                  Text(v.reason!, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detail, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (v.isRequest)
            IconButton(
              tooltip: 'Withdraw request',
              onPressed: () => _cancelRequest(v),
              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ── Small helpers ────────────────────────────────────────────────────────
  Widget _statusChip(AgriOfficer o) {
    final color = o.isOnDuty ? _onDutyColor : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(o.availability.isEmpty ? 'Unknown' : o.availability,
          style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: _floatingDecoration(),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  BoxDecoration _floatingDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      );

  Widget _messageCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildCentered(IconData icon, String text, {Widget? action}) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(text, style: AppTextStyles.bodyMedium),
            ?action,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Visit form (Create)
// ─────────────────────────────────────────────────────────────────────────────
class _RequestVisitSheet extends ConsumerStatefulWidget {
  final AgriOfficer officer;

  const _RequestVisitSheet({required this.officer});

  @override
  ConsumerState<_RequestVisitSheet> createState() => _RequestVisitSheetState();
}

class _RequestVisitSheetState extends ConsumerState<_RequestVisitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _villageCtrl;
  final _reasonCtrl = TextEditingController();
  DateTime? _preferredDate;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final district = ref.read(userProvider).district;
    _villageCtrl = TextEditingController(text: district);
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Preferred visit date',
    );
    if (picked != null) setState(() => _preferredDate = DateTime(picked.year, picked.month, picked.day, 9));
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final farmerId = Supabase.instance.client.auth.currentUser?.id;
    final officerId = widget.officer.id;
    if (farmerId == null || officerId == null) return;

    setState(() => _sending = true);
    try {
      final name = ref.read(userProvider).fullName.trim();
      await ref.read(visitRepositoryProvider).requestVisit(
            farmerId: farmerId,
            farmerName: name.isEmpty ? 'Farmer' : name,
            agriOfficerId: officerId,
            village: _villageCtrl.text.trim(),
            reason: _reasonCtrl.text.trim(),
            preferredDate: _preferredDate,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Request could not be sent. Check your connection and try again.'),
        backgroundColor: Color(0xFFEF4444),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Request a Field Visit', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Ask ${widget.officer.name} (${widget.officer.center}) to inspect your crop on site.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _villageCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your village / farm location *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'The officer needs to know where to come' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'What should the officer look at? *',
                      hintText: 'e.g. Leaves turning yellow across half the paddy field',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Describe the problem in a few words' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Preferred date (optional)',
                        prefixIcon: const Icon(Icons.event_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: _preferredDate != null
                            ? IconButton(
                                tooltip: 'Clear date',
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () => setState(() => _preferredDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _preferredDate != null
                            ? DateFormat('EEE d MMM yyyy').format(_preferredDate!)
                            : 'Any day',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: _preferredDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Sending…' : 'Send Request'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
