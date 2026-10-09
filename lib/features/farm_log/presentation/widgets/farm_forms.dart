import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/features/farm_log/application/farm_provider.dart';
import 'package:plant_disease_detector/features/farm_log/data/farm_models.dart';

const _crops = ['Paddy', 'Tomato', 'Potato', 'Chilli', 'Corn', 'Other'];

/// Leading number of an area such as "2.5 ac" (0 when there is none).
double fieldAcres(FieldBlock f) => double.tryParse(RegExp(r'[\d.]+').firstMatch(f.area)?.group(0) ?? '') ?? 0;

/// Bottom sheet to add a field block. Returns true when one was saved.
Future<bool> showAddFieldSheet(BuildContext context, WidgetRef ref) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AddFieldSheet(),
  );
  if (saved == true) ref.invalidate(fieldBlocksProvider);
  return saved == true;
}

/// Bottom sheet to record a harvest from one of [fields]. Returns true when saved.
Future<bool> showAddHarvestSheet(BuildContext context, WidgetRef ref, List<FieldBlock> fields) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddHarvestSheet(fields: fields),
  );
  if (saved == true) ref.invalidate(yieldEntriesProvider);
  return saved == true;
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AddFieldSheet extends ConsumerStatefulWidget {
  const _AddFieldSheet();

  @override
  ConsumerState<_AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends ConsumerState<_AddFieldSheet> {
  final _name = TextEditingController();
  final _acres = TextEditingController();
  String _crop = 'Paddy';
  String _status = 'healthy';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _acres.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final acres = double.tryParse(_acres.text.trim());
    if (_name.text.trim().isEmpty || acres == null || acres <= 0) {
      setState(() => _error = context.tr(
            en: 'Enter a field name and its size in acres.',
            si: 'ක්ෂේත්‍රයේ නම සහ ප්‍රමාණය (අක්කර) ඇතුළත් කරන්න.',
            ta: 'வயலின் பெயரையும் அளவையும் (ஏக்கர்) உள்ளிடவும்.',
          ));
      return;
    }
    final failText = context.tr(
      en: 'Could not save the field. Check your connection and try again.',
      si: 'ක්ෂේත්‍රය සුරැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
      ta: 'வயலைச் சேமிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(farmApiServiceProvider).createFieldBlock({
        'name': _name.text.trim(),
        'crop': _crop,
        'area': '${acres % 1 == 0 ? acres.toInt() : acres} ac',
        'status': _status,
        'health_score': switch (_status) { 'healthy' => 90, 'monitor' => 60, _ => 30 },
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
        _saving = false;
        _error = failText;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: context.tr(en: 'Add a Field', si: 'ක්ෂේත්‍රයක් එක් කරන්න', ta: 'வயலைச் சேர்க்கவும்'),
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Field name (e.g. North paddy)', si: 'ක්ෂේත්‍රයේ නම (උදා: උතුරු කුඹුර)', ta: 'வயலின் பெயர் (எ.கா. வடக்கு நெல்வயல்)'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _acres,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.tr(en: 'Size (acres)', si: 'ප්‍රමාණය (අක්කර)', ta: 'அளவு (ஏக்கர்)'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(context.tr(en: 'Crop', si: 'බෝගය', ta: 'பயிர்'), style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _crops)
              ChoiceChip(
                label: Text(c == 'Other' ? context.tr(en: 'Other', si: 'වෙනත්', ta: 'மற்றவை') : context.trCrop(c)),
                selected: _crop == c,
                onSelected: (_) => setState(() => _crop = c),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(context.tr(en: 'How does it look now?', si: 'දැන් තත්ත්වය කෙසේද?', ta: 'இப்போது எப்படி இருக்கிறது?'), style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'healthy', label: Text(context.tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியம்'))),
            ButtonSegment(value: 'monitor', label: Text(context.tr(en: 'Monitor', si: 'නිරීක්ෂණය', ta: 'கண்காணி'))),
            ButtonSegment(value: 'at risk', label: Text(context.tr(en: 'At Risk', si: 'අවදානමේ', ta: 'ஆபத்து'))),
          ],
          selected: {_status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr(en: 'Save Field', si: 'ක්ෂේත්‍රය සුරකින්න', ta: 'வயலைச் சேமி'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _AddHarvestSheet extends ConsumerStatefulWidget {
  final List<FieldBlock> fields;
  const _AddHarvestSheet({required this.fields});

  @override
  ConsumerState<_AddHarvestSheet> createState() => _AddHarvestSheetState();
}

class _AddHarvestSheetState extends ConsumerState<_AddHarvestSheet> {
  final _kg = TextEditingController();
  late FieldBlock _field = widget.fields.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _kg.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final kg = int.tryParse(_kg.text.trim());
    if (kg == null || kg <= 0) {
      setState(() => _error = context.tr(en: 'Enter the harvest in kg.', si: 'අස්වැන්න කිලෝග්‍රෑම් වලින් ඇතුළත් කරන්න.', ta: 'அறுவடையை கிலோவில் உள்ளிடவும்.'));
      return;
    }
    final failText = context.tr(
      en: 'Could not save the harvest. Check your connection and try again.',
      si: 'අස්වැන්න සුරැකිය නොහැක. සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
      ta: 'அறுவடையைச் சேமிக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(farmApiServiceProvider).createYieldEntry({
        'field_id': _field.id,
        'crop_name': _field.crop,
        'yield_amount': kg,
        'date': _date.toIso8601String().substring(0, 10),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
        _saving = false;
        _error = failText;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: context.tr(en: 'Record a Harvest', si: 'අස්වැන්නක් සටහන් කරන්න', ta: 'அறுவடையைப் பதிவுசெய்'),
      children: [
        DropdownButtonFormField<FieldBlock>(
          initialValue: _field,
          decoration: InputDecoration(labelText: context.tr(en: 'Field', si: 'ක්ෂේත්‍රය', ta: 'வயல்'), border: const OutlineInputBorder()),
          items: [
            for (final f in widget.fields) DropdownMenuItem(value: f, child: Text('${f.name} · ${context.trCrop(f.crop)}')),
          ],
          onChanged: (f) => setState(() => _field = f ?? _field),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _kg,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Harvest (kg)', si: 'අස්වැන්න (කි.ග්‍රෑ.)', ta: 'அறுவடை (கிலோ)'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text('${context.tr(en: 'Date', si: 'දිනය', ta: 'தேதி')}: ${_date.day}/${_date.month}/${_date.year}'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr(en: 'Save Harvest', si: 'අස්වැන්න සුරකින්න', ta: 'அறுவடையைச் சேமி'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
