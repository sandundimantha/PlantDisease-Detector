import 'package:flutter/material.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/core/providers/user_provider.dart';
import 'package:plant_disease_detector/features/expert_consult/presentation/screens/consultation_status_screen.dart';
import 'package:plant_disease_detector/features/officer/data/consultation_repository.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/nearest_officer_screen.dart';
import 'package:plant_disease_detector/models/agri_officer.dart';
import 'package:plant_disease_detector/models/consultation.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExpertConsultScreen — farmer escalates a crop problem to an officer.
// CRUD: Read (officers, my requests) · Create (consultation request)
// Requests land in the officer's Case Inbox.
// ─────────────────────────────────────────────────────────────────────────────
class ExpertConsultScreen extends ConsumerStatefulWidget {
  // Optional prefill when opened from a diagnosis result.
  final String? diseaseName;
  final String? scanId;
  final String? imageUrl;
  final String? crop;
  final String? severity;

  const ExpertConsultScreen({super.key, this.diseaseName, this.scanId, this.imageUrl, this.crop, this.severity});

  @override
  ConsumerState<ExpertConsultScreen> createState() => _ExpertConsultScreenState();
}

class _ExpertConsultScreenState extends ConsumerState<ExpertConsultScreen> {
  String _selectedFilter = 'All';

  List<AgriOfficer> _applyFilter(List<AgriOfficer> officers) {
    switch (_selectedFilter) {
      case 'All':
        return officers;
      case 'On Duty':
        return officers.where((o) => o.isOnDuty).toList();
      default:
        return officers.where((o) => o.specializations.contains(_selectedFilter)).toList();
    }
  }

  Future<void> _openStatus(String consultationId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConsultationStatusScreen(consultationId: consultationId)),
    );
    ref.invalidate(myConsultationsProvider);
  }

  Future<void> _openRequestForm(AgriOfficer? officer) async {
    final created = await showModalBottomSheet<Consultation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestConsultSheet(
        officer: officer,
        initialDisease: widget.diseaseName,
        scanId: widget.scanId,
        imageUrl: widget.imageUrl,
        initialCrop: widget.crop,
        initialSeverity: widget.severity,
      ),
    );
    if (created == null || !mounted) return;
    ref.invalidate(myConsultationsProvider);
    await _openStatus(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(agriOfficersProvider);
    final requestsAsync = ref.watch(myConsultationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Expert Consult', si: 'විශේෂඥ උපදෙස්', ta: 'நிபுணர் ஆலோசனை')),
        actions: const [LanguageSelectorButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRequestForm(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          context.tr(en: 'New Request', si: 'නව ඉල්ලීමක්', ta: 'புதிய கோரிக்கை'),
          style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agriOfficersProvider);
          ref.invalidate(myConsultationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildMyRequests(requestsAsync),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(context.tr(en: 'Agricultural Officers', si: 'කෘෂිකර්ම නිලධාරීන්', ta: 'வேளாண் அலுவலர்கள்'),
                      style: AppTextStyles.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearestOfficerScreen()),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: Text(context.tr(en: 'Map view', si: 'සිතියම', ta: 'வரைபடம்')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            officersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _buildMessage(
                Icons.wifi_off_rounded,
                context.tr(en: 'Could not load officers. Pull down to retry.', si: 'නිලධාරීන් පූරණය කළ නොහැක. නැවත උත්සාහ කිරීමට පහළට අදින්න.', ta: 'அதிகாரிகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்க கீழே இழுக்கவும்.'),
              ),
              data: (officers) {
                final specialisations = {
                  for (final o in officers) ...o.specializations,
                }.toList()
                  ..sort();
                final filters = ['All', 'On Duty', ...specialisations];
                final filtered = _applyFilter(officers);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterRow(filters),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      _buildMessage(Icons.person_search_rounded, context.tr(en: 'No officers match this filter.', si: 'මෙම පෙරහනට ගැලපෙන නිලධාරීන් නොමැත.', ta: 'இந்த வடிப்பானுக்குப் பொருந்தும் அதிகாரிகள் இல்லை.'))
                    else
                      ...filtered.map(_buildOfficerCard),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Read: the farmer's own requests ─────────────────────────────────────
  Widget _buildMyRequests(AsyncValue<List<Consultation>> requestsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(en: 'My Requests', si: 'මගේ ඉල්ලීම්', ta: 'எனது கோரிக்கைகள்'),
            style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        requestsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _buildMessage(Icons.error_outline_rounded, context.tr(en: 'Could not load your requests.', si: 'ඔබේ ඉල්ලීම් පූරණය කළ නොහැක.', ta: 'உங்கள் கோரிக்கைகளை ஏற்ற முடியவில்லை.')),
          data: (requests) {
            if (requests.isEmpty) {
              return _buildMessage(
                Icons.forum_outlined,
                context.tr(en: 'No requests yet. Ask an officer about a crop problem and track the reply here.', si: 'තවම ඉල්ලීම් නැත. වගාවේ ගැටලුවක් ගැන නිලධාරියෙකුගෙන් විමසා පිළිතුර මෙතැනින් ලුහුබඳින්න.', ta: 'இன்னும் கோரிக்கைகள் இல்லை. பயிர் பிரச்சனை பற்றி ஒரு அதிகாரியிடம் கேட்டு பதிலைக் கண்காணிக்கவும்.'),
              );
            }
            return Column(children: requests.map(_buildRequestTile).toList());
          },
        ),
      ],
    );
  }

  Widget _buildRequestTile(Consultation c) {
    final (label, color) = consultationStatusStyle(c, context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => _openStatus(c.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.eco_rounded, color: color),
        ),
        title: Text(c.diseaseName ?? context.tr(en: 'Crop problem', si: 'වගාවේ ගැටලුවක්', ta: 'பயிர் பிரச்சனை'), style: AppTextStyles.titleSmall),
        subtitle: Text(
          c.officerName != null ? '${c.timeAgo} • ${c.officerName}' : c.timeAgo,
          style: AppTextStyles.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<String> filters) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                filter == 'All' ? context.tr(en: 'All', si: 'සියල්ල', ta: 'அனைத்தும்') : filter == 'On Duty' ? context.tr(en: 'On Duty', si: 'රාජකාරියේ', ta: 'பணியில்') : filter,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfficerCard(AgriOfficer officer) {
    final onDuty = officer.isOnDuty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  officer.initial,
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(officer.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(officer.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(officer.center, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (onDuty ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  officer.availability,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: onDuty ? const Color(0xFF047857) : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (officer.specializations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: officer.specializations
                  .map((s) => Chip(
                        label: Text(s, style: AppTextStyles.bodySmall),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.background,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openRequestForm(officer),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 20),
              label: Text(context.tr(en: 'Request Consult', si: 'උපදෙස් ඉල්ලන්න', ta: 'ஆலோசனை கோருக')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

/// Shared label/colour for a consultation's status (farmer-facing wording).
(String, Color) consultationStatusStyle(Consultation c, BuildContext context) {
  if (c.isResolved) return (context.tr(en: 'Answered', si: 'පිළිතුරු දුන්නා', ta: 'பதிலளிக்கப்பட்டது'), const Color(0xFF047857));
  if (c.isCancelled) return (context.tr(en: 'Cancelled', si: 'අවලංගු කළා', ta: 'ரத்து செய்யப்பட்டது'), Colors.grey.shade600);
  if (c.isOpen) return (context.tr(en: 'In Review', si: 'සමාලෝචනයේ', ta: 'மதிப்பாய்வில்'), const Color(0xFF1D4ED8));
  return (context.tr(en: 'Waiting', si: 'බලාපොරොත්තුවෙන්', ta: 'காத்திருக்கிறது'), const Color(0xFFB45309));
}

// ─────────────────────────────────────────────────────────────────────────────
// Request form (Create)
// ─────────────────────────────────────────────────────────────────────────────
class _RequestConsultSheet extends ConsumerStatefulWidget {
  final AgriOfficer? officer;
  final String? initialDisease;
  final String? scanId;
  final String? imageUrl;

  final String? initialCrop;
  final String? initialSeverity;

  const _RequestConsultSheet({this.officer, this.initialDisease, this.scanId, this.imageUrl, this.initialCrop, this.initialSeverity});

  @override
  ConsumerState<_RequestConsultSheet> createState() => _RequestConsultSheetState();
}

class _RequestConsultSheetState extends ConsumerState<_RequestConsultSheet> {
  static const _crops = ['Tomato', 'Potato', 'Paddy', 'Chilli', 'Other'];
  static const _severities = {'low': 'Low', 'medium': 'Medium', 'high': 'High'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _problemCtrl;
  late final TextEditingController _locationCtrl;
  final _detailsCtrl = TextEditingController();
  String _crop = 'Tomato';
  String _severity = 'medium';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _problemCtrl = TextEditingController(text: widget.initialDisease ?? '');
    // Prefill from the scan result when opened from there.
    final crop = widget.initialCrop;
    if (crop != null) _crop = _crops.contains(crop) ? crop : 'Other';
    if (widget.initialSeverity case 'low' || 'medium' || 'high') _severity = widget.initialSeverity!;
    _locationCtrl = TextEditingController(text: ref.read(userProvider).district);
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _locationCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final farmerId = Supabase.instance.client.auth.currentUser?.id;
    if (farmerId == null) {
      _showError(context.tr(en: 'Please log in again to send a request.', si: 'කරුණාකර ඉල්ලීමක් යැවීමට නැවත ලොග් වන්න.', ta: 'கோரிக்கையை அனுப்ப மீண்டும் உள்நுழையவும்.'));
      return;
    }

    setState(() => _submitting = true);
    final notes = [
      'Crop: $_crop',
      if (widget.officer != null) 'Requested officer: ${widget.officer!.name}',
      if (_detailsCtrl.text.trim().isNotEmpty) _detailsCtrl.text.trim(),
    ].join('\n');

    try {
      final created = await ref.read(consultationRepositoryProvider).createConsultation(
            farmerId: farmerId,
            scanId: widget.scanId,
            imageUrl: widget.imageUrl,
            diseaseName: _problemCtrl.text.trim(),
            severity: _severity,
            location: _locationCtrl.text.trim(),
            notes: notes,
          );
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr(en: 'Request could not be sent. Check your connection and try again.', si: 'ඉල්ලීම යැවිය නොහැක. ඔබගේ සබැඳුම පරීක්ෂා කර නැවත උත්සාහ කරන්න.', ta: 'கோரிக்கையை அனுப்ப முடியவில்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.'));
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)),
    );
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
              // Re-check fields as the farmer types so a fixed error disappears.
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
                  Text(context.tr(en: 'Request Expert Consult', si: 'විශේෂඥ උපදෙස් ඉල්ලන්න', ta: 'நிபுணர் ஆலோசனை கோருக'), style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    widget.officer != null
                        ? context.tr(en: 'Your request goes to the officer case inbox. ${widget.officer!.name} or the next available officer will reply.', si: 'ඔබේ ඉල්ලීම නිලධාරීන්ට යැවේ. ${widget.officer!.name} හෝ ඊළඟට සිටින නිලධාරියා පිළිතුරු දෙනු ඇත.', ta: 'உங்கள் கோரிக்கை அதிகாரிகளுக்கு அனுப்பப்படும். ${widget.officer!.name} அல்லது அடுத்த அதிகாரி பதிலளிப்பார்.')
                        : context.tr(en: 'Your request goes to the officer case inbox. The next available officer will reply.', si: 'ඔබේ ඉල්ලීම නිලධාරීන්ට යැවේ. ඊළඟට සිටින නිලධාරියා පිළිතුරු දෙනු ඇත.', ta: 'உங்கள் கோரிக்கை அதிகாரிகளுக்கு அனுப்பப்படும். அடுத்த அதிகாரி பதிலளிப்பார்.'),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  if (widget.scanId != null || widget.imageUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: widget.imageUrl != null
                                  ? SmartImage(src: widget.imageUrl!, fit: BoxFit.cover)
                                  : Container(color: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.eco_rounded, color: AppColors.primary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr(
                                en: 'Your scan result and photo are attached, so the officer can see what you saw.',
                                si: 'ඔබේ ස්කෑන් ප්‍රතිඵලය සහ ඡායාරූපය අමුණා ඇත, එබැවින් නිලධාරියාට ඔබ දුටු දේ දැකිය හැක.',
                                ta: 'உங்கள் ஸ்கேன் முடிவும் படமும் இணைக்கப்பட்டுள்ளன; அலுவலர் நீங்கள் பார்த்ததைப் பார்க்கலாம்.',
                              ),
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(context.tr(en: 'Crop', si: 'වගාව', ta: 'பயிர்'), style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _crops.map((c) => ChoiceChip(
                          label: Text(context.trCrop(c)),
                          selected: _crop == c,
                          onSelected: (_) => setState(() => _crop = c),
                        )).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _problemCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: context.tr(en: 'Problem / suspected disease *', si: 'ගැටලුව / සැක සහිත රෝගය *', ta: 'பிரச்சனை / சந்தேகிக்கப்படும் நோய் *'),
                      hintText: context.tr(en: 'e.g. Brown spots on lower leaves', si: 'උදා: පහළ පත්‍ර වල දුඹුරු ලප', ta: 'உதாரணமாக: கீழ் இலைகளில் பழுப்பு புள்ளிகள்'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? context.tr(en: 'Describe the problem in a few words', si: 'ගැටලුව වචන කිහිපයකින් විස්තර කරන්න', ta: 'பிரச்சனையை சில வார்த்தைகளில் விவரிக்கவும்')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(context.tr(en: 'How serious is it?', si: 'මෙය කොතරම් බරපතලද?', ta: 'இது எவ்வளவு தீவிரமானது?'), style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: _severities.entries
                        .map((e) => ButtonSegment(value: e.key, label: Text(context.trSeverity(e.value))))
                        .toList(),
                    selected: {_severity},
                    onSelectionChanged: (s) => setState(() => _severity = s.first),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr(en: 'Village / district *', si: 'ගම / දිස්ත්‍රික්කය *', ta: 'கிராமம் / மாவட்டம் *'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? context.tr(en: 'Officers need your location to help', si: 'උදව් කිරීමට නිලධාරීන්ට ඔබගේ ස්ථානය අවශ්‍යයි', ta: 'உதவ அதிகாரிகளுக்கு உங்கள் இருப்பிடம் தேவை')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _detailsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: context.tr(en: 'More details (optional)', si: 'වැඩිදුර විස්තර (අත්‍යවශ්‍ය නොවේ)', ta: 'மேலும் விவரங்கள் (கட்டாயமில்லை)'),
                      hintText: context.tr(en: 'When did it start? How much of the field is affected?', si: 'මෙය ආරම්භ වූයේ කවදාද? කොපමණ වගාවක් බලපෑමට ලක්වී තිබේද?', ta: 'இது எப்போது தொடங்கியது? வயலின் எவ்வளவு பகுதி பாதிக்கப்பட்டுள்ளது?'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? context.tr(en: 'Sending…', si: 'යවමින් පවතී…', ta: 'அனுப்பப்படுகிறது…') : context.tr(en: 'Send Request', si: 'ඉල්ලීම යවන්න', ta: 'கோரிக்கையை அனுப்புக')),
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
