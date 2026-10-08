import 'package:flutter/material.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_comparison_screen.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/disease_detail_screen.dart';
import 'package:plant_disease_detector/features/treatment/data/disease_model.dart';
import 'package:plant_disease_detector/l10n/app_localizations.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';

class DiseaseCatalogueScreen extends StatefulWidget {
  const DiseaseCatalogueScreen({super.key});

  @override
  State<DiseaseCatalogueScreen> createState() => _DiseaseCatalogueScreenState();
}

class _DiseaseCatalogueScreenState extends State<DiseaseCatalogueScreen> {
  String _searchQuery = '';
  String _selectedCrop = 'All';
  final List<Disease> _selectedForCompare = [];

  late Future<List<Disease>> _diseasesFuture;

  /// Every disease the AI model can detect (26 diseases from the catalog).
  static final List<Disease> _catalogDiseases = [
    for (final info in DiseaseCatalog.all)
      if (!info.isHealthy) Disease.fromCatalog(info),
  ];

  /// Common Sri Lankan diseases outside the AI model's 38 classes.
  static const List<Disease> _extraDiseases = [
    Disease(
      id: 'cat_d4',
      name: 'Potato Black Scurf',
      cropName: 'Potato',
      severity: DiseaseSeverity.medium,
      description: 'Hard dark brown to black sclerotial patches adhering to tuber skin.',
      symptoms: ['Black dirt-like specks on tubers', 'Stem cankers below soil line', 'Aerial tubers formation'],
      causes: ['Rhizoctonia solani fungus', 'Cold damp soils at planting', 'Infected seed tubers'],
      treatments: ['Use certified disease-free seed', 'Crop rotation with corn/grasses', 'Tuber treatment with Trichoderma'],
      imageUrl: '',
    ),
    Disease(
      id: 'cat_d5',
      name: 'Paddy Bacterial Blight',
      cropName: 'Paddy',
      severity: DiseaseSeverity.high,
      description: 'Water-soaked translucent streaks turning white-yellow with wavy margins along leaf tips.',
      symptoms: ['Yellowing along leaf margin', 'Milky bacterial ooze on young lesions', 'Kresek wilt in seedling stage'],
      causes: ['Xanthomonas oryzae pv. oryzae', 'Severe storms and flooding', 'Excess nitrogen fertilization'],
      treatments: ['Drain flooded field temporarily', 'Apply Copper Hydroxide (Rs. 1,350)', 'Balanced split potash application'],
      imageUrl: 'assets/images/scan_bacterial.jpg',
    ),
    Disease(
      id: 'cat_d6',
      name: 'Paddy Blast',
      cropName: 'Paddy',
      severity: DiseaseSeverity.high,
      description: 'Spindle-shaped elliptical lesions with gray centers and reddish-brown borders.',
      symptoms: ['Diamond-shaped eye lesions on leaves', 'Rotten neck on panicles', 'White empty grains'],
      causes: ['Magnaporthe oryzae fungus', 'High relative humidity >90%', 'Frequent overcast days'],
      treatments: ['Apply Tricyclazole 75% WP (Rs. 1,800)', 'Avoid excessive urea fertilizer', 'Burn stubble after harvest'],
      imageUrl: 'assets/images/scan_paddy.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _diseasesFuture = _fetchDiseases();
  }

  Future<List<Disease>> _fetchDiseases() async {
    try {
      final response = await Supabase.instance.client.from('diseases').select('*');
      final fromDb = response.map<Disease>((json) => Disease.fromJson(json)).toList();
      return _merge([...fromDb, ..._extraDiseases]);
    } catch (_) {
      // Offline: the catalog and extras are bundled with the app
      return _merge(_extraDiseases);
    }
  }

  /// Catalog first; other sources only add diseases the catalog does not cover.
  static List<Disease> _merge(List<Disease> others) {
    final seen = {for (final d in _catalogDiseases) d.name.toLowerCase()};
    final list = [..._catalogDiseases];
    for (final d in others) {
      if (seen.add(d.name.toLowerCase())) list.add(d);
    }
    list.sort((a, b) => a.cropName == b.cropName ? a.name.compareTo(b.name) : a.cropName.compareTo(b.cropName));
    return list;
  }

  void _toggleCompare(Disease disease) {
    setState(() {
      final exists = _selectedForCompare.any((d) => d.id == disease.id);
      if (exists) {
        _selectedForCompare.removeWhere((d) => d.id == disease.id);
      } else {
        if (_selectedForCompare.length >= 2) {
          _selectedForCompare.removeAt(0); // Keep max 2
        }
        _selectedForCompare.add(disease);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSinhala = l10n?.localeName == 'si';
    final isTamil = l10n?.localeName == 'ta';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(context.tr(en: 'Disease Catalogue', si: 'රෝග නාමාවලිය', ta: 'நோய் பட்டியல்')),
        actions: [
          const LanguageSelectorButton(isCompact: true),
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiseaseComparisonScreen(
                    diseaseA: _selectedForCompare.isNotEmpty ? _selectedForCompare[0] : null,
                    diseaseB: _selectedForCompare.length > 1 ? _selectedForCompare[1] : null,
                  ),
                ),
              );
            },
            tooltip: context.tr(en: 'Compare Diseases', si: 'රෝග සංසන්දනය කරන්න', ta: 'நோய்களை ஒப்பிடுக'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      hintText: isSinhala
                          ? 'බෝග රෝග සොයන්න...'
                          : (isTamil ? 'பயிர் நோய்களைத் தேடுங்கள்...' : 'Search crop diseases...'),
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Crop filter chips, built from the crops in the list
              FutureBuilder<List<Disease>>(
                future: _diseasesFuture,
                builder: (context, snapshot) {
                  final crops = ['All', ...{for (final d in snapshot.data ?? _catalogDiseases) d.cropName}];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: crops.map((crop) {
                        final isSelected = _selectedCrop == crop;
                        final cropLabel = crop == 'All'
                            ? context.tr(en: 'All Crops', si: 'සියලු බෝග', ta: 'அனைத்து பயிர்கள்')
                            : context.trCrop(crop);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCrop = crop),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Text(
                                cropLabel,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Disease List
              Expanded(
                child: FutureBuilder<List<Disease>>(
                  future: _diseasesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    final diseases = snapshot.data ?? _catalogDiseases;
                    final q = _searchQuery.trim().toLowerCase();
                    final filteredDiseases = diseases.where((d) {
                      final matchesQuery = q.isEmpty ||
                          d.name.toLowerCase().contains(q) ||
                          d.cropName.toLowerCase().contains(q) ||
                          context.trDisease(d.name).toLowerCase().contains(q) ||
                          context.trCrop(d.cropName).toLowerCase().contains(q);
                      final matchesCrop = _selectedCrop == 'All' || d.cropName.toLowerCase() == _selectedCrop.toLowerCase();
                      return matchesQuery && matchesCrop;
                    }).toList();

                    if (filteredDiseases.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr(en: 'No diseases found', si: 'රෝග හමු නොවීය', ta: 'நோய்கள் எதுவும் இல்லை'),
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, _selectedForCompare.length == 2 ? 96 : 24),
                      itemCount: filteredDiseases.length,
                      itemBuilder: (context, index) {
                        return _buildDiseaseCard(filteredDiseases[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Wireframe 6: Sticky bottom comparison CTA when 2 diseases selected
          if (_selectedForCompare.length == 2)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiseaseComparisonScreen(
                          diseaseA: _selectedForCompare[0],
                          diseaseB: _selectedForCompare[1],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 20),
                  label: Text(
                    context.tr(
                      en: 'COMPARE 2 SELECTED DISEASES',
                      si: 'තෝරාගත් රෝග 2 සංසන්දනය කරන්න',
                      ta: 'தேர்ந்தெடுக்கப்பட்ட 2 நோய்களை ஒப்பிடுக',
                    ),
                    style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(Disease disease) {
    final isSelectedForCompare = _selectedForCompare.any((d) => d.id == disease.id);
    final cropTranslated = context.trCrop(disease.cropName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelectedForCompare ? AppColors.primary : AppColors.border,
          width: isSelectedForCompare ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelectedForCompare
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DiseaseDetailScreen(disease: disease)));
          },
          child: Row(
            children: [
              Hero(
                tag: 'disease_img_${disease.id}',
                child: disease.imageUrl.isEmpty
                    ? Container(
                        width: 90,
                        height: 96,
                        decoration: BoxDecoration(
                          color: disease.severityColor.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                        ),
                        child: Icon(Icons.eco_rounded, color: disease.severityColor, size: 36),
                      )
                    : SmartImage(
                        src: disease.imageUrl,
                        width: 90,
                        height: 96,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trDisease(disease.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.grass_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(cropTranslated, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(width: 8),
                          Text(
                            context.trSeverity(disease.severityLabel),
                            style: TextStyle(color: disease.severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Wireframe 6: [ Compare + ] Toggle
              GestureDetector(
                onTap: () => _toggleCompare(disease),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelectedForCompare
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelectedForCompare ? Icons.check_rounded : Icons.add_rounded,
                        color: isSelectedForCompare ? Colors.white : AppColors.primary,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isSelectedForCompare
                            ? context.tr(en: 'Selected', si: 'තෝරාගත්', ta: 'தேர்ந்தெடுக்கப்பட்டது')
                            : context.tr(en: 'Compare', si: 'සංසන්දනය', ta: 'ஒப்பிடுக'),
                        style: TextStyle(
                          color: isSelectedForCompare ? Colors.white : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
