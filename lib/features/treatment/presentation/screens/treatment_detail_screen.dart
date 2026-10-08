import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/features/treatment/presentation/screens/treatment_reminder_screen.dart';
import 'package:plant_disease_detector/shared/widgets/smart_image.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';

class TreatmentDetailScreen extends StatefulWidget {
  final String diseaseName;
  final String cropName;

  const TreatmentDetailScreen({
    super.key,
    this.diseaseName = 'Tomato Early Blight',
    this.cropName = 'Tomato',
  });

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Organic', 'Chemical', 'Cultural'];

  // Checkbox state for tasks: map key = '$tabIndex-$taskIndex'
  final Map<String, bool> _stepStates = {};

  DiseaseInfo? get _info => DiseaseCatalog.lookup(widget.diseaseName);

  // Indicative retail prices (LKR) for common pack sizes in Sri Lanka.
  static const Map<String, (String, int, IconData)> _products = {
    'mancozeb': ('Mancozeb 80% WP · 1 kg', 1200, Icons.science_outlined),
    'copper': ('Copper Oxychloride 50% WP · 500 g', 950, Icons.science_outlined),
    'chlorothalonil': ('Chlorothalonil 75% WP · 500 g', 1450, Icons.science_outlined),
    'metalaxyl': ('Metalaxyl + Mancozeb · 250 g', 2100, Icons.science_outlined),
    'captan': ('Captan 50% WP · 500 g', 1300, Icons.science_outlined),
    'propiconazole': ('Propiconazole 250 EC · 100 ml', 1100, Icons.science_outlined),
    'azoxystrobin': ('Azoxystrobin 250 SC · 100 ml', 1900, Icons.science_outlined),
    'myclobutanil': ('Myclobutanil 10% WP · 100 g', 1250, Icons.science_outlined),
    'hexaconazole': ('Hexaconazole 5% SC · 100 ml', 650, Icons.science_outlined),
    'imidacloprid': ('Imidacloprid 200 SL · 100 ml', 850, Icons.pest_control_outlined),
    'abamectin': ('Abamectin 1.8 EC · 100 ml', 900, Icons.pest_control_outlined),
    'sulphur': ('Wettable Sulphur 80% · 1 kg', 600, Icons.eco_outlined),
    'neem': ('Neem Oil · 250 ml', 950, Icons.eco_outlined),
  };

  static const _chemicalWords = [
    'fungicide', 'bactericide', 'miticide', 'mancozeb', 'copper', 'chlorothalonil', 'captan',
    'propiconazole', 'azoxystrobin', 'myclobutanil', 'metalaxyl', 'hexaconazole', 'imidacloprid', 'abamectin',
  ];

  /// 0 organic · 1 chemical · 2 cultural
  static int _category(DiseaseStep step) {
    final text = '${step.title} ${step.desc}'.toLowerCase();
    if (_chemicalWords.any(text.contains)) return 1;
    if (text.contains('neem') || text.contains('sulphur')) return 0;
    return 2;
  }

  /// Steps for the selected tab: this disease's own steps first, then general
  /// advice that is safe for any crop.
  List<Map<String, dynamic>> _tasksFor(int tab) {
    final own = (_info?.treatments ?? const <DiseaseStep>[])
        .where((s) => _category(s) == tab && !s.title.startsWith('Confirm with'))
        .map((s) => {
              'title': context.trTreatment(s.title),
              'subtitle': context.trTreatment(s.desc),
              'time': context.tr(en: 'For this disease', si: 'මෙම රෝගය සඳහා', ta: 'இந்த நோய்க்கு'),
              'own': true,
            });
    final general = switch (tab) {
      0 => [
          {
            'title': context.tr(en: 'Neem Leaf Extract Spray', si: 'කොහොඹ කොළ සාර ඉසීම', ta: 'வேப்பிலைச் சாறு தெளிப்பு'),
            'subtitle': context.tr(en: 'Mix 50 ml neem oil with a little soap in 10 L water; spray in the evening.', si: 'කොහොඹ තෙල් මි.ලී. 50 ක් සබන් ස්වල්පයක් සමඟ ජලය ලීටර් 10 ක මිශ්‍ර කර සවස ඉසින්න.', ta: '50 மி.லி வேப்ப எண்ணெயை சிறிது சோப்புடன் 10 லி நீரில் கலந்து மாலையில் தெளிக்கவும்.'),
            'time': context.tr(en: 'Evening', si: 'සවස', ta: 'மாலை'),
          },
          {
            'title': context.tr(en: 'Trichoderma Bio-Agent', si: 'ට්‍රයිකොඩර්මා ජෛව කාරකය', ta: 'டிரைக்கோடெர்மா உயிர்க்காரணி'),
            'subtitle': context.tr(en: 'Mix the bio-culture into compost before applying it around the plants.', si: 'පැල වටා යෙදීමට පෙර ජෛව සංස්කෘතිය කොම්පෝස්ට් සමඟ මිශ්‍ර කරන්න.', ta: 'செடிகளைச் சுற்றி இடுவதற்கு முன் உயிர்க் கலவையை உரத்துடன் கலக்கவும்.'),
            'time': context.tr(en: 'Weekly', si: 'සතිපතා', ta: 'வாராந்திர'),
          },
          {
            'title': context.tr(en: 'Add Compost', si: 'කොම්පෝස්ට් යොදන්න', ta: 'மட்கிய உரம் இடுங்கள்'),
            'subtitle': context.tr(en: 'Well-rotted compost feeds the soil and helps plants resist disease.', si: 'හොඳින් දිරාපත් වූ කොම්පෝස්ට් පස පෝෂණය කර පැලවලට රෝගවලට ඔරොත්තු දීමට උපකාරී වේ.', ta: 'நன்கு மட்கிய உரம் மண்ணை வளப்படுத்தி செடிகள் நோயை எதிர்க்க உதவுகிறது.'),
            'time': context.tr(en: 'Before planting', si: 'සිටුවීමට පෙර', ta: 'நடவுக்கு முன்'),
          },
        ],
      1 => [
          {
            'title': context.tr(en: 'Wear Protective Gear', si: 'ආරක්ෂක ඇඳුම් පළඳින්න', ta: 'பாதுகாப்பு உடை அணியுங்கள்'),
            'subtitle': context.tr(en: 'Gloves, mask and goggles; do not spray against the wind.', si: 'අත්වැසුම්, මුහුණු ආවරණ සහ ඇස් කණ්ණාඩි; සුළඟට එරෙහිව ඉසින්න එපා.', ta: 'கையுறை, முகக்கவசம், கண்ணாடி; காற்றுக்கு எதிராகத் தெளிக்க வேண்டாம்.'),
            'time': context.tr(en: 'Before spraying', si: 'ඉසීමට පෙර', ta: 'தெளிப்பதற்கு முன்'),
          },
          {
            'title': context.tr(en: 'Respect the Waiting Period', si: 'පොරොත්තු කාලය රකින්න', ta: 'காத்திருப்பு காலத்தைக் கடைப்பிடியுங்கள்'),
            'subtitle': context.tr(en: 'Do not harvest before the pre-harvest interval on the label.', si: 'ලේබලයේ සඳහන් අස්වනු පෙර කාලය ගතවීමට පෙර අස්වනු නොනෙළන්න.', ta: 'லேபிளில் உள்ள அறுவடைக்கு முந்தைய இடைவெளிக்கு முன் அறுவடை செய்ய வேண்டாம்.'),
            'time': context.tr(en: 'See label', si: 'ලේබලය බලන්න', ta: 'லேபிளைப் பார்க்கவும்'),
          },
        ],
      _ => [
          {
            'title': context.tr(en: 'Space Plants Well', si: 'පැල අතර හොඳ පරතරයක් තබන්න', ta: 'செடிகளுக்கு நல்ல இடைவெளி விடுங்கள்'),
            'subtitle': context.tr(en: 'Good spacing lets air move and leaves dry quickly.', si: 'හොඳ පරතරය වාතය ගමන් කිරීමට සහ කොළ ඉක්මනින් වියළීමට ඉඩ දෙයි.', ta: 'நல்ல இடைவெளி காற்று செல்லவும் இலைகள் விரைவாக உலரவும் உதவுகிறது.'),
            'time': context.tr(en: 'Planting stage', si: 'සිටුවීමේ අවධිය', ta: 'நடவு நிலை'),
          },
          {
            'title': context.tr(en: 'Water at the Base', si: 'මුල් අසලට ජලය දමන්න', ta: 'அடிப்பகுதியில் நீர் பாய்ச்சுங்கள்'),
            'subtitle': context.tr(en: 'Drip or base watering keeps leaves dry and slows disease.', si: 'බිංදු හෝ මුල් අසලට ජලය දැමීම කොළ වියළිව තබා රෝග අඩු කරයි.', ta: 'சொட்டு அல்லது அடிப்பகுதி நீர்ப்பாசனம் இலைகளை உலர்வாக வைத்து நோயைக் குறைக்கிறது.'),
            'time': context.tr(en: 'Daily', si: 'දිනපතා', ta: 'தினமும்'),
          },
          {
            'title': context.tr(en: 'Rotate Crops', si: 'බෝග මාරු කරන්න', ta: 'பயிர்களைச் சுழற்சி செய்யுங்கள்'),
            'subtitle': context.tr(en: 'Do not plant the same crop family in the same bed next season.', si: 'ඊළඟ කන්නයේ එම පාත්තියේම එකම බෝග පවුල වගා නොකරන්න.', ta: 'அடுத்த பருவத்தில் அதே பாத்தியில் அதே பயிர்க் குடும்பத்தை நட வேண்டாம்.'),
            'time': context.tr(en: 'Next season', si: 'ඊළඟ කන්නය', ta: 'அடுத்த பருவம்'),
          },
        ],
    };
    return [...own, ...general];
  }

  /// Products named in this disease's steps for the tab (organic: neem/sulphur,
  /// chemical: active ingredients). Cultural steps need no purchases.
  List<(String, int, IconData)> _productsFor(int tab) {
    if (tab == 2) return const [];
    final text = (_info?.treatments ?? const <DiseaseStep>[])
        .where((s) => _category(s) == tab)
        .map((s) => '${s.title} ${s.desc}'.toLowerCase())
        .join(' ');
    final keys = tab == 0 ? ['neem', 'sulphur'] : _products.keys.where((k) => k != 'neem' && k != 'sulphur');
    final found = [for (final k in keys) if (text.contains(k)) _products[k]!];
    if (found.isEmpty && tab == 0) return [_products['neem']!];
    return found;
  }

  String _costLabel(List<(String, int, IconData)> products) {
    if (products.isEmpty) return context.tr(en: 'No purchase needed', si: 'මිලදී ගැනීමක් අවශ්‍ය නැත', ta: 'வாங்க வேண்டியதில்லை');
    final total = products.fold<int>(0, (sum, p) => sum + p.$2);
    return '${context.tr(en: 'Est. Cost', si: 'ඇස්තමේන්තු පිරිවැය', ta: 'மதிப்பிடப்பட்ட செலவு')}: Rs. ${_formatRs(total)}';
  }

  static String _formatRs(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final tasks = _tasksFor(_selectedTabIndex);
    final products = _productsFor(_selectedTabIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Premium Image Header ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.primary,
                actions: const [
                  LanguageSelectorButton(isDark: true, isCompact: true),
                ],
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${context.trDisease(widget.diseaseName)} ${context.tr(en: 'Plan', si: 'සැලැස්ම', ta: 'திட்டம்')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const SmartImage(
                        src: 'assets/images/hero_leaf.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Dark gradient overlay for text readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_info != null) ...[
                        Text(
                          '${context.tr(en: 'Cause', si: 'හේතුව', ta: 'காரணம்')}: ${_info!.pathogen}',
                          style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Overview / Estimated Cost Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _costLabel(products),
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${context.tr(en: 'Crop', si: 'බෝගය', ta: 'பயிர்')}: ${context.trCrop(widget.cropName)} • ${context.tr(en: 'Indicative prices', si: 'ආසන්න මිල', ta: 'தோராயமான விலைகள்')}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Segmented Tabs: Organic / Chemical / Cultural
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isSelected = _selectedTabIndex == index;
                            final tabLabels = [
                              context.tr(en: 'Organic', si: 'කාබනික', ta: 'இயற்கை'),
                              context.tr(en: 'Chemical', si: 'රසායනික', ta: 'இரசாயன'),
                              context.tr(en: 'Cultural', si: 'කෘෂිකාර්මික', ta: 'பயிற்சி முறை'),
                            ];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tabLabels[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step-by-step Treatment Tasks
                      Text(
                        context.tr(en: 'Step-by-Step Action Plan', si: 'පියවරෙන් පියවර ක්‍රියාකාරී සැලැස්ම', ta: 'படிபடியான செயல் திட்டம்'),
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Column(
                        children: List.generate(tasks.length, (index) {
                          final task = tasks[index];
                          final key = '$_selectedTabIndex-$index';
                          final isDone = _stepStates[key] ?? false;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _stepStates[key] = !isDone;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppColors.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDone ? AppColors.primary : AppColors.cardBorder,
                                  width: isDone ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isDone ? AppColors.primary : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'] as String,
                                          style: AppTextStyles.titleSmall.copyWith(
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color: isDone
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          task['subtitle'] as String,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: task['own'] == true ? AppColors.primary.withValues(alpha: 0.12) : AppColors.cardSurface,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task['time'] as String,
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: task['own'] == true ? AppColors.primary : AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Products named in the steps above, with indicative prices
                      if (products.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr(en: 'Recommended Inputs (LKR)', si: 'නිර්දේශිත ද්‍රව්‍ය (රු.)', ta: 'பரிந்துரைக்கப்பட்ட பொருட்கள் (ரூ.)'),
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(context.tr(en: 'Indicative', si: 'ආසන්න', ta: 'தோராயம்'), style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 84,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: products.length,
                            itemBuilder: (context, idx) {
                              final (name, price, icon) = products[idx];
                              return _buildProductCard(name, 'Rs. ${_formatRs(price)}', icon);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            en: 'Follow the dose on the product label and check with your Agriculture Instructor before spraying.',
                            si: 'නිෂ්පාදන ලේබලයේ මාත්‍රාව අනුගමනය කර ඉසීමට පෙර ඔබේ කෘෂිකර්ම උපදේශකගෙන් විමසන්න.',
                            ta: 'தயாரிப்பு லேபிளில் உள்ள அளவைப் பின்பற்றி, தெளிப்பதற்கு முன் உங்கள் வேளாண் போதனாசிரியரிடம் உறுதிப்படுத்தவும்.',
                          ),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 120), // Bottom button clearance
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Button: Schedule Reminder
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreatmentReminderScreen(
                            treatmentTitle: tasks.isNotEmpty ? tasks.first['title'] as String : _tabs[_selectedTabIndex],
                            diseaseName: widget.diseaseName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.alarm_rounded, color: Colors.white),
                    label: Text(
                      context.tr(en: 'Schedule Treatment Reminder', si: 'ප්‍රතිකාර මතක් කිරීමක් සකසන්න', ta: 'சிகிச்சை நினைவூட்டலை திட்டமிடுங்கள்'),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
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

  Widget _buildProductCard(String name, String price, IconData icon) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
