// ─────────────────────────────────────────────────────────────────────────────
// DiseaseCatalog — what the app knows about each label the on-device model can
// return (assets/models/labels.txt, 38 PlantVillage classes). The scan result
// screen uses it for the crop, pathogen, severity, symptoms and treatment plan.
//
// Treatment steps are general extension advice; product names are common
// active ingredients sold in Sri Lanka. Farmers are told to follow the label
// dose and confirm with their Agriculture Instructor before spraying.
// ─────────────────────────────────────────────────────────────────────────────

class DiseaseStep {
  final String title;
  final String desc;
  const DiseaseStep(this.title, this.desc);
}

class DiseaseInfo {
  final String label;
  final String crop;
  final String pathogen;
  final String severity; // 'none' | 'low' | 'medium' | 'high'
  final bool treatable;
  final String nameSi;
  final String nameTa;
  final List<String> symptoms;
  final List<DiseaseStep> treatments;

  const DiseaseInfo({
    required this.label,
    required this.crop,
    required this.pathogen,
    required this.severity,
    required this.treatable,
    required this.nameSi,
    required this.nameTa,
    required this.symptoms,
    required this.treatments,
  });

  bool get isHealthy => severity == 'none';
}

const _healthySymptoms = [
  'Leaves have even green colour with no spots or lesions',
  'No wilting, curling or unusual yellowing',
  'No fungal growth, powder or mould on the leaf surface',
  'Keep scanning weekly to catch problems early',
];

const _healthyCare = [
  DiseaseStep('Keep Monitoring', 'Check the underside of leaves every week, especially after rain.'),
  DiseaseStep('Water at the Base', 'Water the soil, not the leaves, early in the morning.'),
  DiseaseStep('Balanced Fertiliser', 'Follow the Department of Agriculture fertiliser recommendation for this crop.'),
  DiseaseStep('Field Hygiene', 'Remove weeds and fallen leaves that can carry disease.'),
];

const _virusControl = DiseaseStep(
  'No Cure — Stop the Spread',
  'Viral diseases cannot be cured. Remove and destroy infected plants to protect the rest of the field.',
);

const _askOfficer = DiseaseStep(
  'Confirm with an Officer',
  'Use Expert Help to send this scan to your Agriculture Instructor before spraying.',
);

DiseaseInfo _healthy(String crop, String si, String ta) => DiseaseInfo(
      label: 'Healthy $crop',
      crop: crop,
      pathogen: 'No pathogen detected',
      severity: 'none',
      treatable: false,
      nameSi: si,
      nameTa: ta,
      symptoms: _healthySymptoms,
      treatments: _healthyCare,
    );

class DiseaseCatalog {
  static final Map<String, DiseaseInfo> _byLabel = {
    for (final d in _all) d.label: d,
  };

  /// Every label the model can return, in labels.txt order.
  static List<DiseaseInfo> get all => List.unmodifiable(_all);

  /// Info for a model label, or null for labels the app does not know.
  static DiseaseInfo? lookup(String label) => _byLabel[label.trim()];

  static String localizedName(String label, String langCode) {
    final info = lookup(label);
    if (info == null || langCode == 'en') return label;
    return langCode == 'si' ? info.nameSi : info.nameTa;
  }

  static final List<DiseaseInfo> _all = [
    // ── Apple ────────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Apple Scab', crop: 'Apple', pathogen: 'Venturia inaequalis', severity: 'medium', treatable: true,
      nameSi: 'ඇපල් කබල් රෝගය', nameTa: 'ஆப்பிள் சொறி நோய்',
      symptoms: [
        'Olive-green to black velvety spots on leaves',
        'Spots turn dark and corky as they age',
        'Infected leaves curl, yellow and drop early',
        'Cracked, scabby dark patches on fruit',
      ],
      treatments: [
        DiseaseStep('Remove Fallen Leaves', 'Rake and destroy fallen leaves where the fungus survives.'),
        DiseaseStep('Protective Fungicide', 'Spray mancozeb or captan at bud break and repeat every 7–10 days in wet weather.'),
        DiseaseStep('Prune for Airflow', 'Open the canopy so leaves dry quickly after rain.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Apple Black Rot', crop: 'Apple', pathogen: 'Botryosphaeria obtusa', severity: 'high', treatable: true,
      nameSi: 'ඇපල් කළු කුණුවීම', nameTa: 'ஆப்பிள் கருப்பு அழுகல்',
      symptoms: [
        'Purple spots on leaves that enlarge with brown centres ("frog-eye")',
        'Fruit rot starting at the blossom end, turning black',
        'Shrivelled black mummified fruit on the tree',
        'Sunken cankers on branches',
      ],
      treatments: [
        DiseaseStep('Remove Infected Wood', 'Prune out cankers and dead branches 15 cm below the damage.'),
        DiseaseStep('Clear Mummified Fruit', 'Pick and destroy shrivelled fruit; it carries spores to next season.'),
        DiseaseStep('Fungicide Cover', 'Apply captan or a copper fungicide from petal fall at label intervals.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Apple Cedar Rust', crop: 'Apple', pathogen: 'Gymnosporangium juniperi-virginianae', severity: 'low', treatable: true,
      nameSi: 'ඇපල් මලකඩ රෝගය', nameTa: 'ஆப்பிள் துரு நோய்',
      symptoms: [
        'Bright yellow-orange spots on the upper leaf surface',
        'Small tube-like growths under the spots',
        'Leaves yellow and fall early in severe cases',
        'Deformed fruit with orange spots',
      ],
      treatments: [
        DiseaseStep('Remove Alternate Hosts', 'Cut down nearby juniper/cedar plants that carry the rust.'),
        DiseaseStep('Fungicide at Bloom', 'Spray myclobutanil or mancozeb from pink bud stage for 3–4 rounds.'),
        DiseaseStep('Resistant Varieties', 'Choose rust-resistant apple varieties for new planting.'),
        _askOfficer,
      ],
    ),
    _healthy('Apple', 'නිරෝගී ඇපල්', 'ஆரோக்கியமான ஆப்பிள்'),
    _healthy('Blueberry', 'නිරෝගී බ්ලූබෙරි', 'ஆரோக்கியமான புளூபெர்ரி'),

    // ── Cherry ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Cherry Powdery Mildew', crop: 'Cherry', pathogen: 'Podosphaera clandestina', severity: 'medium', treatable: true,
      nameSi: 'චෙරි පිටිපුස් රෝගය', nameTa: 'செர்ரி சாம்பல் நோய்',
      symptoms: [
        'White powdery patches on young leaves',
        'Leaves curl upward and become distorted',
        'New shoots grow slowly',
        'Powdery spots on fruit near harvest',
      ],
      treatments: [
        DiseaseStep('Sulphur Spray', 'Apply wettable sulphur at first sign and repeat every 10–14 days.'),
        DiseaseStep('Prune Crowded Growth', 'Thin dense shoots to improve air movement and sunlight.'),
        DiseaseStep('Avoid Excess Nitrogen', 'Too much nitrogen produces soft growth that mildew attacks.'),
        _askOfficer,
      ],
    ),
    _healthy('Cherry', 'නිරෝගී චෙරි', 'ஆரோக்கியமான செர்ரி'),

    // ── Corn (maize) ─────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Corn Gray Leaf Spot', crop: 'Corn', pathogen: 'Cercospora zeae-maydis', severity: 'medium', treatable: true,
      nameSi: 'ඉරිඟු අළු පත්‍ර ලප', nameTa: 'சோளம் சாம்பல் இலைப்புள்ளி',
      symptoms: [
        'Long, narrow rectangular grey-tan spots between leaf veins',
        'Spots start on lower leaves and move upward',
        'Spots join and kill large areas of the leaf',
        'Worse in warm, humid weather with heavy dew',
      ],
      treatments: [
        DiseaseStep('Crop Rotation', 'Do not plant maize in the same field next season; rotate with legumes.'),
        DiseaseStep('Bury Residue', 'Plough in old maize stalks where the fungus survives.'),
        DiseaseStep('Fungicide if Severe', 'Spray propiconazole or azoxystrobin when spots reach the leaves above the cob.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Corn Common Rust', crop: 'Corn', pathogen: 'Puccinia sorghi', severity: 'medium', treatable: true,
      nameSi: 'ඉරිඟු මලකඩ රෝගය', nameTa: 'சோளம் துரு நோய்',
      symptoms: [
        'Small cinnamon-brown powdery pustules on both leaf surfaces',
        'Pustules rub off as rusty powder on fingers',
        'Leaves yellow and dry in heavy infection',
        'Spreads quickly in cool, moist weather',
      ],
      treatments: [
        DiseaseStep('Resistant Hybrids', 'Plant rust-tolerant maize hybrids recommended for your district.'),
        DiseaseStep('Early Fungicide', 'Spray mancozeb or propiconazole when pustules first appear before tasselling.'),
        DiseaseStep('Timely Planting', 'Plant at the start of the season so crops mature before peak rust.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Corn Northern Leaf Blight', crop: 'Corn', pathogen: 'Exserohilum turcicum', severity: 'high', treatable: true,
      nameSi: 'ඉරිඟු උතුරු පත්‍ර අංගමාරය', nameTa: 'சோளம் வடக்கு இலைக் கருகல்',
      symptoms: [
        'Long cigar-shaped grey-green lesions (3–15 cm)',
        'Lesions turn tan and may show dark spores',
        'Starts on lower leaves, spreads upward',
        'Large dead areas reduce cob filling',
      ],
      treatments: [
        DiseaseStep('Fungicide Spray', 'Apply mancozeb or propiconazole at first lesions; repeat after 10–14 days.'),
        DiseaseStep('Rotate Crops', 'Avoid maize-after-maize; rotate for at least one season.'),
        DiseaseStep('Manage Residue', 'Plough in infected stalks after harvest.'),
        _askOfficer,
      ],
    ),
    _healthy('Corn', 'නිරෝගී ඉරිඟු', 'ஆரோக்கியமான சோளம்'),

    // ── Grape ────────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Grape Black Rot', crop: 'Grape', pathogen: 'Guignardia bidwellii', severity: 'high', treatable: true,
      nameSi: 'මිදි කළු කුණුවීම', nameTa: 'திராட்சை கருப்பு அழுகல்',
      symptoms: [
        'Round reddish-brown leaf spots with dark borders',
        'Tiny black dots inside the spots',
        'Berries turn brown, then shrivel into hard black mummies',
        'Lesions on shoots and tendrils',
      ],
      treatments: [
        DiseaseStep('Remove Mummies', 'Pick off and destroy shrivelled berries and infected leaves.'),
        DiseaseStep('Fungicide Programme', 'Spray mancozeb or myclobutanil from new shoot growth to berry set.'),
        DiseaseStep('Open the Canopy', 'Train and prune vines so bunches get sun and air.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Grape Black Measles', crop: 'Grape', pathogen: 'Phaeomoniella / Phaeoacremonium spp. (Esca)', severity: 'high', treatable: false,
      nameSi: 'මිදි එස්කා (කළු සරම්ප)', nameTa: 'திராட்சை எஸ்கா நோய்',
      symptoms: [
        'Yellow or red stripes between leaf veins ("tiger stripes")',
        'Small dark spots on berries',
        'Sudden drying of whole shoots in hot weather',
        'Dark streaks inside the wood when cut',
      ],
      treatments: [
        DiseaseStep('Prune Out Dead Wood', 'Cut infected arms back to healthy wood and burn the prunings.'),
        DiseaseStep('Protect Pruning Wounds', 'Seal large cuts with a wound sealant to stop new infection.'),
        DiseaseStep('Replace Badly Affected Vines', 'There is no cure; replace vines that decline each year.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Grape Leaf Blight', crop: 'Grape', pathogen: 'Pseudocercospora vitis (Isariopsis)', severity: 'medium', treatable: true,
      nameSi: 'මිදි පත්‍ර අංගමාරය', nameTa: 'திராட்சை இலைக் கருகல்',
      symptoms: [
        'Irregular dark red-brown spots on older leaves',
        'Spots have a yellow margin',
        'Leaves dry and fall early',
        'Vines weaken over the season',
      ],
      treatments: [
        DiseaseStep('Remove Infected Leaves', 'Collect and destroy spotted leaves and leaf litter.'),
        DiseaseStep('Copper or Mancozeb', 'Spray copper oxychloride or mancozeb every 10–14 days in wet periods.'),
        DiseaseStep('Improve Airflow', 'Prune to avoid a dense, humid canopy.'),
        _askOfficer,
      ],
    ),
    _healthy('Grape', 'නිරෝගී මිදි', 'ஆரோக்கியமான திராட்சை'),

    // ── Citrus ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Citrus Greening', crop: 'Orange', pathogen: 'Candidatus Liberibacter asiaticus (Huanglongbing)', severity: 'high', treatable: false,
      nameSi: 'පැඟිරි කොළ කහවීම (සිට්‍රස් ග්‍රීනිං)', nameTa: 'சிட்ரஸ் பசுமை நோய்',
      symptoms: [
        'Blotchy, uneven yellowing on leaves (not matching on both sides)',
        'Small, upright, yellow leaves on affected branches',
        'Small, lopsided, bitter fruit that stays green',
        'Branches die back over time',
      ],
      treatments: [
        _virusControl,
        DiseaseStep('Control the Psyllid', 'The disease is spread by the citrus psyllid; spray imidacloprid on new flushes.'),
        DiseaseStep('Use Certified Plants', 'Plant only disease-free nursery stock.'),
        _askOfficer,
      ],
    ),

    // ── Peach ────────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Peach Bacterial Spot', crop: 'Peach', pathogen: 'Xanthomonas arboricola pv. pruni', severity: 'medium', treatable: true,
      nameSi: 'පීච් බැක්ටීරියා ලප', nameTa: 'பீச் பாக்டீரியா புள்ளி',
      symptoms: [
        'Small water-soaked spots that turn purple-black',
        'Spot centres drop out leaving "shot holes"',
        'Leaves yellow and fall',
        'Sunken spots and cracks on fruit',
      ],
      treatments: [
        DiseaseStep('Copper Spray', 'Apply copper oxychloride at leaf fall and early spring.'),
        DiseaseStep('Avoid Overhead Water', 'Bacteria spread in water splash; water at the base.'),
        DiseaseStep('Balanced Feeding', 'Avoid excess nitrogen that makes leaves more susceptible.'),
        _askOfficer,
      ],
    ),
    _healthy('Peach', 'නිරෝගී පීච්', 'ஆரோக்கியமான பீச்'),

    // ── Pepper ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Pepper Bacterial Spot', crop: 'Pepper', pathogen: 'Xanthomonas campestris pv. vesicatoria', severity: 'medium', treatable: true,
      nameSi: 'මාළු මිරිස් බැක්ටීරියා ලප', nameTa: 'குடைமிளகாய் பாக்டீரியா புள்ளி',
      symptoms: [
        'Small water-soaked spots on leaves that turn brown',
        'Spots have a yellow halo',
        'Heavy leaf drop exposes fruit to sunscald',
        'Raised scabby spots on fruit',
      ],
      treatments: [
        DiseaseStep('Remove Infected Plants', 'Pull out badly infected plants and destroy them.'),
        DiseaseStep('Copper Bactericide', 'Spray copper hydroxide or copper oxychloride every 7–10 days in wet weather.'),
        DiseaseStep('Clean Seed', 'Use certified seed and do not work in the field when leaves are wet.'),
        _askOfficer,
      ],
    ),
    _healthy('Pepper', 'නිරෝගී මාළු මිරිස්', 'ஆரோக்கியமான குடைமிளகாய்'),

    // ── Potato ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Potato Early Blight', crop: 'Potato', pathogen: 'Alternaria solani', severity: 'medium', treatable: true,
      nameSi: 'අර්තාපල් මුල් අංගමාරය', nameTa: 'உருளைக்கிழங்கு ஆரம்ப கருகல்',
      symptoms: [
        'Dark brown spots with concentric rings (target pattern)',
        'Yellow area around each spot',
        'Older, lower leaves are affected first',
        'Small dark sunken spots on tubers',
      ],
      treatments: [
        DiseaseStep('Remove Lower Leaves', 'Pick off and destroy the first infected leaves.'),
        DiseaseStep('Fungicide Spray', 'Apply mancozeb or chlorothalonil every 7–10 days once spots appear.'),
        DiseaseStep('Feed the Crop', 'Well-fed plants resist early blight; follow the fertiliser recommendation.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Potato Late Blight', crop: 'Potato', pathogen: 'Phytophthora infestans', severity: 'high', treatable: true,
      nameSi: 'අර්තාපල් පසු අංගමාරය', nameTa: 'உருளைக்கிழங்கு பிந்தைய கருகல்',
      symptoms: [
        'Large, dark, water-soaked patches on leaves',
        'White fluffy growth under leaves in humid weather',
        'Stems turn brown-black and plants collapse quickly',
        'Reddish-brown rot inside tubers',
      ],
      treatments: [
        DiseaseStep('Act Within 24 Hours', 'Late blight can destroy a field in days. Remove and burn infected plants now.'),
        DiseaseStep('Systemic Fungicide', 'Spray metalaxyl + mancozeb, then continue with mancozeb every 7 days in cool wet weather.'),
        DiseaseStep('Protect Tubers', 'Hill up soil around plants and harvest only after the tops have died.'),
        _askOfficer,
      ],
    ),
    _healthy('Potato', 'නිරෝගී අර්තාපල්', 'ஆரோக்கியமான உருளைக்கிழங்கு'),
    _healthy('Raspberry', 'නිරෝගී රාස්බෙරි', 'ஆரோக்கியமான ராஸ்பெர்ரி'),
    _healthy('Soybean', 'නිරෝගී සෝයා', 'ஆரோக்கியமான சோயா'),

    // ── Squash ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Squash Powdery Mildew', crop: 'Squash', pathogen: 'Podosphaera xanthii', severity: 'medium', treatable: true,
      nameSi: 'වට්ටක්කා පිටිපුස් රෝගය', nameTa: 'பூசணி சாம்பல் நோய்',
      symptoms: [
        'White powdery spots on upper leaf surfaces',
        'Spots spread to cover whole leaves and stems',
        'Leaves turn yellow, then brown and dry',
        'Smaller fruit and lower yield',
      ],
      treatments: [
        DiseaseStep('Sulphur or Hexaconazole', 'Spray wettable sulphur or hexaconazole at first sign; repeat every 10 days.'),
        DiseaseStep('Remove Old Leaves', 'Cut off heavily covered leaves to slow spread.'),
        DiseaseStep('Space Plants', 'Give vines room so leaves get sun and air.'),
        _askOfficer,
      ],
    ),

    // ── Strawberry ───────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Strawberry Leaf Scorch', crop: 'Strawberry', pathogen: 'Diplocarpon earlianum', severity: 'medium', treatable: true,
      nameSi: 'ස්ට්‍රෝබෙරි පත්‍ර දැවීම', nameTa: 'ஸ்ட்ராபெர்ரி இலை கருகல்',
      symptoms: [
        'Many small irregular purple spots on leaves',
        'Spots merge and leaves look burnt',
        'Leaf edges dry and curl',
        'Weak plants with fewer runners',
      ],
      treatments: [
        DiseaseStep('Remove Old Leaves', 'Clear infected leaves after harvest.'),
        DiseaseStep('Fungicide Spray', 'Apply captan or a copper fungicide during wet periods.'),
        DiseaseStep('Drip Irrigation', 'Keep leaves dry; water at the base.'),
        _askOfficer,
      ],
    ),
    _healthy('Strawberry', 'නිරෝගී ස්ට්‍රෝබෙරි', 'ஆரோக்கியமான ஸ்ட்ராபெர்ரி'),

    // ── Tomato ───────────────────────────────────────────────────────────────
    const DiseaseInfo(
      label: 'Tomato Bacterial Spot', crop: 'Tomato', pathogen: 'Xanthomonas spp.', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි බැක්ටීරියා ලප', nameTa: 'தக்காளி பாக்டீரியா புள்ளி',
      symptoms: [
        'Small dark water-soaked spots on leaves',
        'Spots have a yellow halo and may tear',
        'Leaves yellow and drop',
        'Raised scabby spots on green fruit',
      ],
      treatments: [
        DiseaseStep('Remove Infected Leaves', 'Pick off spotted leaves and destroy them away from the field.'),
        DiseaseStep('Copper Spray', 'Apply copper oxychloride every 7–10 days during rainy weather.'),
        DiseaseStep('Stop Splash', 'Mulch the soil and avoid overhead watering.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Early Blight', crop: 'Tomato', pathogen: 'Alternaria solani', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි මුල් අංගමාරිය', nameTa: 'தக்காளி ஆரம்ப கருகல்',
      symptoms: [
        'Dark brown concentric rings on leaves',
        'Yellow halo surrounding lesions',
        'Premature leaf drop and defoliation',
        'Affects lower leaves first, spreads upward',
      ],
      treatments: [
        DiseaseStep('Remove Affected Leaves', 'Prune and destroy all visibly infected foliage immediately.'),
        DiseaseStep('Apply Fungicide', 'Use copper-based or chlorothalonil fungicide every 7–10 days.'),
        DiseaseStep('Improve Air Circulation', 'Space plants adequately. Avoid overhead irrigation.'),
        DiseaseStep('Soil Nutrition', 'Boost potassium levels to strengthen plant immunity.'),
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Late Blight', crop: 'Tomato', pathogen: 'Phytophthora infestans', severity: 'high', treatable: true,
      nameSi: 'තක්කාලි පසු අංගමාරිය', nameTa: 'தக்காளி பிந்தைய கருகல்',
      symptoms: [
        'Large irregular water-soaked dark patches without rings',
        'White fluffy fungal growth on leaf undersides in humidity',
        'Rapid stem browning and sudden plant wilt',
        'Dark greasy firm rot on green tomato fruits',
      ],
      treatments: [
        DiseaseStep('Remove and burn infected foliage immediately', 'Late blight spreads in days in cool, wet weather.'),
        DiseaseStep('Apply Mancozeb 80% WP protectant (Rs. 1,200 / 1kg)', 'Spray every 7 days while the weather stays wet.'),
        DiseaseStep('Metalaxyl + Mancozeb systemic spray (Rs. 2,100 / 250g)', 'Use when the disease is already in the field.'),
        DiseaseStep('Switch strictly to drip irrigation at root level', 'Keep leaves dry to stop new infections.'),
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Leaf Mold', crop: 'Tomato', pathogen: 'Passalora fulva', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි පත්‍ර පුස්', nameTa: 'தக்காளி இலை பூஞ்சணம்',
      symptoms: [
        'Pale yellow patches on the upper leaf surface',
        'Olive-green to brown velvety mould under the patches',
        'Leaves curl, wither and drop',
        'Common in humid polytunnels and greenhouses',
      ],
      treatments: [
        DiseaseStep('Lower Humidity', 'Ventilate polytunnels and avoid wetting leaves.'),
        DiseaseStep('Remove Lower Leaves', 'Strip infected lower leaves to improve airflow.'),
        DiseaseStep('Fungicide Spray', 'Apply chlorothalonil or mancozeb at label intervals.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Septoria Leaf Spot', crop: 'Tomato', pathogen: 'Septoria lycopersici', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි සෙප්ටෝරියා පත්‍ර ලප', nameTa: 'தக்காளி செப்டோரியா இலைப்புள்ளி',
      symptoms: [
        'Many small round spots with grey centres and dark edges',
        'Tiny black dots in the centre of each spot',
        'Lower leaves turn yellow and fall first',
        'Fruit is usually not spotted, but yield drops',
      ],
      treatments: [
        DiseaseStep('Remove Infected Leaves', 'Pick off spotted lower leaves as soon as they appear.'),
        DiseaseStep('Fungicide Spray', 'Apply chlorothalonil or mancozeb every 7–10 days.'),
        DiseaseStep('Mulch and Rotate', 'Mulch to stop soil splash and avoid tomatoes in the same bed next season.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Spider Mites', crop: 'Tomato', pathogen: 'Tetranychus urticae (two-spotted spider mite)', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි මකුළු මයිටාවන්', nameTa: 'தக்காளி சிலந்திப் பூச்சி',
      symptoms: [
        'Tiny yellow or white speckles on leaves',
        'Fine webbing under leaves and between stems',
        'Leaves turn bronze, dry and fall',
        'Worse in hot, dry weather',
      ],
      treatments: [
        DiseaseStep('Wash Off Mites', 'Spray water under the leaves to knock mites off.'),
        DiseaseStep('Miticide Spray', 'Apply abamectin or wettable sulphur, covering leaf undersides.'),
        DiseaseStep('Neem Oil', 'Neem-based sprays help keep numbers down between treatments.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Target Spot', crop: 'Tomato', pathogen: 'Corynespora cassiicola', severity: 'medium', treatable: true,
      nameSi: 'තක්කාලි ඉලක්ක ලප', nameTa: 'தக்காளி இலக்கு புள்ளி',
      symptoms: [
        'Brown spots with light centres and target-like rings',
        'Spots start small and grow to 1 cm or more',
        'Leaves yellow and drop from the bottom up',
        'Sunken spots on fruit',
      ],
      treatments: [
        DiseaseStep('Remove Infected Leaves', 'Destroy spotted leaves and crop debris.'),
        DiseaseStep('Fungicide Spray', 'Apply chlorothalonil or azoxystrobin at label intervals.'),
        DiseaseStep('Improve Airflow', 'Stake and prune plants so leaves dry quickly.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Yellow Leaf Curl Virus', crop: 'Tomato', pathogen: 'Tomato yellow leaf curl virus (Begomovirus)', severity: 'high', treatable: false,
      nameSi: 'තක්කාලි කොළ කොඩවීමේ වෛරසය', nameTa: 'தக்காளி மஞ்சள் இலை சுருட்டை வைரஸ்',
      symptoms: [
        'Leaves curl upward and become small and cup-shaped',
        'Yellow leaf edges and between veins',
        'Plants are stunted and bushy',
        'Flowers drop and very few fruits set',
      ],
      treatments: [
        _virusControl,
        DiseaseStep('Control Whiteflies', 'Whiteflies spread the virus; use yellow sticky traps and spray imidacloprid or neem.'),
        DiseaseStep('Protect Seedlings', 'Raise seedlings under insect-proof net and plant tolerant varieties.'),
        _askOfficer,
      ],
    ),
    const DiseaseInfo(
      label: 'Tomato Mosaic Virus', crop: 'Tomato', pathogen: 'Tomato mosaic virus (Tobamovirus)', severity: 'medium', treatable: false,
      nameSi: 'තක්කාලි මොසෙයික් වෛරසය', nameTa: 'தக்காளி மொசைக் வைரஸ்',
      symptoms: [
        'Light and dark green mottled pattern on leaves',
        'Leaves are distorted, narrow or fern-like',
        'Plants grow slowly',
        'Uneven ripening and brown streaks on fruit',
      ],
      treatments: [
        _virusControl,
        DiseaseStep('Clean Hands and Tools', 'The virus spreads by touch; wash hands and disinfect tools between plants.'),
        DiseaseStep('Healthy Seed', 'Use certified seed and resistant varieties next season.'),
        _askOfficer,
      ],
    ),
    _healthy('Tomato', 'නිරෝගී තක්කාලි', 'ஆரோக்கியமான தக்காளி'),
  ];
}
