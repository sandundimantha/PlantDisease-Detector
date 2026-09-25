import 'package:flutter/material.dart';

/// Context extension for instant, reactive, multi-language string lookup.
/// Dynamically updates whenever the app locale changes (en, si, ta).
extension AppLocalizationContext on BuildContext {
  String tr({required String en, required String si, required String ta}) {
    final code = Localizations.localeOf(this).languageCode;
    if (code == 'si') return si;
    if (code == 'ta') return ta;
    return en;
  }

  /// Translates common disease names automatically across all screens
  String trDisease(String diseaseName) {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings.translateDisease(diseaseName, code);
  }

  /// Translates symptom descriptions
  String trSymptom(String symptom) {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings.translateSymptom(symptom, code);
  }

  /// Translates treatment texts
  String trTreatment(String text) {
    final code = Localizations.localeOf(this).languageCode;
    return AppStrings.translateTreatment(text, code);
  }

  /// Translates severity labels
  String trSeverity(String severity) {
    final s = severity.trim().toLowerCase();
    if (s.contains('high')) return tr(en: 'High', si: 'ඉහළ', ta: 'அதிகம்');
    if (s.contains('medium')) return tr(en: 'Medium', si: 'මධ්‍යම', ta: 'நடுத்தரம்');
    if (s.contains('low')) return tr(en: 'Low', si: 'අඩු', ta: 'குறைவு');
    if (s.contains('healthy') || s.contains('none')) return tr(en: 'Healthy', si: 'නිරෝගී', ta: 'ஆரோக்கியமானது');
    return severity;
  }

  /// Translates crop names
  String trCrop(String crop) {
    final c = crop.trim().toLowerCase();
    if (c == 'tomato') return tr(en: 'Tomato', si: 'තක්කාලි', ta: 'தக்காளி');
    if (c == 'potato') return tr(en: 'Potato', si: 'අර්තාපල්', ta: 'உருளைக்கிழங்கு');
    if (c == 'paddy' || c == 'rice') return tr(en: 'Paddy', si: 'වී / ගොයම්', ta: 'நெல்');
    if (c == 'corn' || c == 'maize') return tr(en: 'Corn', si: 'ඉරිඟු', ta: 'சோளம்');
    if (c == 'chilli' || c == 'pepper') return tr(en: 'Chilli', si: 'මිරිස්', ta: 'மிளகாய்');
    return crop;
  }

  /// Translates relative dates like "Today", "Yesterday"
  String trDate(String dateLabel) {
    if (dateLabel.startsWith('Today')) {
      return dateLabel.replaceFirst('Today', tr(en: 'Today', si: 'අද', ta: 'இன்று'));
    }
    if (dateLabel.startsWith('Yesterday')) {
      return dateLabel.replaceFirst('Yesterday', tr(en: 'Yesterday', si: 'ඊයේ', ta: 'நேற்று'));
    }
    return dateLabel;
  }

  bool get isSinhala => Localizations.localeOf(this).languageCode == 'si';
  bool get isTamil => Localizations.localeOf(this).languageCode == 'ta';
}

/// Static helper for cases outside of direct widget build trees.
class AppStrings {
  static String tr(String langCode, {required String en, required String si, required String ta}) {
    if (langCode == 'si') return si;
    if (langCode == 'ta') return ta;
    return en;
  }

  static final Map<String, Map<String, String>> _diseaseDict = {
    'Tomato Early Blight': {
      'si': 'තක්කාලි මුල් අංගමාරිය',
      'ta': 'தக்காளி ஆரம்ப கருகல்',
    },
    'Leaf Curl Virus': {
      'si': 'කොළ කොඩවීම (වෛරසය)',
      'ta': 'இலை சுருட்டை வைரஸ்',
    },
    'Healthy Crop': {
      'si': 'නිරෝගී වගාව',
      'ta': 'ஆரோக்கியமான பயிர்',
    },
    'Powdery Mildew': {
      'si': 'පිටිපුස් රෝගය',
      'ta': 'சாம்பல் நோய்',
    },
    'Bacterial Leaf Spot': {
      'si': 'බැක්ටීරියා පත්‍ර ලප',
      'ta': 'பாக்டீரியா இலைப்புள்ளி',
    },
    'Tomato Late Blight': {
      'si': 'තක්කාලි පසු අංගමාරිය',
      'ta': 'தக்காளி பிந்தைய கருகல்',
    },
    'Corn Rust': {
      'si': 'ඉරිඟු මලකඩ රෝගය',
      'ta': 'சோள துரு நோய்',
    },
    'Chilli Anthracnose': {
      'si': 'මිරිස් ඇන්ත්‍රැක්නෝස් (කරටි කුණුවීම)',
      'ta': 'மிளகாய் ஆந்த்ராக்னோஸ்',
    },
    'Paddy Blast': {
      'si': 'ගොයම් කොළ පාළුව',
      'ta': 'நெல் குலை நோய்',
    },
  };

  static final Map<String, Map<String, String>> _symptomDict = {
    'Dark brown concentric rings on leaves': {
      'si': 'පත්‍ර මත තද දුඹුරු වෘත්තාකාර ලප',
      'ta': 'இலைகளில் அடர் பழுப்பு நிற வளையங்கள்',
    },
    'Yellow halo surrounding lesions': {
      'si': 'තුවාල වටා ඇති කහ පැහැති වළල්ල',
      'ta': 'புண்களைச் சுற்றியுள்ள மஞ்சள் வளையம்',
    },
    'Premature leaf drop and defoliation': {
      'si': 'කල් තබා කොළ හැලී යාම',
      'ta': 'முன்கூட்டியே இலை உதிர்தல்',
    },
    'Affects lower leaves first, spreads upward': {
      'si': 'පළමුව පහළ පත්‍ර වලට බලපා ඉහළට පැතිරේ',
      'ta': 'முதலில் கீழ் இலைகளை பாதித்து, மேலே பரவுகிறது',
    },
    'No pathogen detected': {
      'si': 'රෝග කාරක හමු නොවීය',
      'ta': 'நோய்க்கிருமி எதுவும் இல்லை',
    },
    'Brown spots with concentric rings (target board pattern)': {
      'si': 'වෘත්තාකාර වළලු සහිත දුඹුරු ලප',
      'ta': 'வட்ட வடிவ வளையங்களைக் கொண்ட பழுப்பு புள்ளிகள்',
    },
    'Premature defoliation and fruit collar rot': {
      'si': 'කල් තබා පත්‍ර හැලීම සහ ගෙඩි කුණුවීම',
      'ta': 'முன்கூட்டியே இலை உதிர்தல் மற்றும் காய் அழுகல்',
    },
    'Large irregular water-soaked dark patches without rings': {
      'si': 'වළලු නොමැති විශාල තෙතමනය සහිත අඳුරු ලප',
      'ta': 'வளையங்கள் இல்லாத பெரிய ஒழுங்கற்ற ஈரமான கரும்புள்ளிகள்',
    },
    'White fluffy fungal growth on leaf undersides in humidity': {
      'si': 'ආර්ද්‍රතාවයේදී පත්‍ර යට සුදු පුළුන් වැනි දිලීර වර්ධනය',
      'ta': 'ஈரப்பதத்தில் இலைகளின் அடிப்பகுதியில் வெள்ளை பூஞ்சை வளர்ச்சி',
    },
    'Rapid stem browning and sudden plant wilt': {
      'si': 'කඳ වේගයෙන් දුඹුරු වීම සහ හදිසි මැලවීම',
      'ta': 'தண்டு விரைவாக பழுப்பாதல் மற்றும் திடீர் வாடல்',
    },
    'Dark greasy firm rot on green tomato fruits': {
      'si': 'අමු තක්කාලි ගෙඩි මත තද තෙල් සහිත කුණුවීම',
      'ta': 'பச்சை தக்காளி பழங்களில் அடர் எண்ணெய் அழுகல்',
    },
    'Alternaria solani fungus spores': {
      'si': 'Alternaria solani දිලීර බීජාණු',
      'ta': 'Alternaria solani பூஞ்சை வித்துக்கள்',
    },
    'High humidity (>80%) and warm temps (24–29°C)': {
      'si': 'ඉහළ ආර්ද්‍රතාවය (>80%) සහ උණුසුම් උෂ්ණත්වය (24–29°C)',
      'ta': 'அதிக ஈரப்பதம் (>80%) மற்றும் வெப்பம் (24–29°C)',
    },
    'Splash dispersal via rain or overhead irrigation': {
      'si': 'වැසි හෝ ඉහළින් ජලය යෙදීමෙන් විසිරීම',
      'ta': 'மழை அல்லது மேல் தெளிப்பு பாசனம் மூலம் பரவுதல்',
    },
    'Phytophthora infestans oomycete pathogen': {
      'si': 'Phytophthora infestans රෝග කාරකය',
      'ta': 'Phytophthora infestans நோய்க்கிருமி',
    },
    'Cool wet weather (15–20°C) with persistent fog/rain': {
      'si': 'මීදුම/වැසි සහිත සිසිල් තෙත් කාලගුණය (15–20°C)',
      'ta': 'தொடர்ச்சியான மூடுபனி/மழையுடன் கூடிய குளிர்ந்த ஈரமான வானிலை (15–20°C)',
    },
    'Wind-blown sporangia across neighboring fields': {
      'si': 'අසල්වැසි කුඹුරු හරහා සුළඟින් ගසාගෙන යන බීජාණු',
      'ta': 'அண்டை வயல்களில் இருந்து காற்று மூலம் பரவும் வித்துக்கள்',
    },
  };

  static final Map<String, Map<String, String>> _treatmentDict = {
    'Remove Affected Leaves': {
      'si': 'බලපෑමට ලක්වූ පත්‍ර ඉවත් කරන්න',
      'ta': 'பாதிக்கப்பட்ட இலைகளை அகற்றவும்',
    },
    'Prune and destroy all visibly infected foliage immediately.': {
      'si': 'රෝගී වූ සියලුම පත්‍ර කපා වහාම විනාශ කරන්න.',
      'ta': 'பாதிக்கப்பட்ட அனைத்து இலைகளையும் உடனடியாக அப்புறப்படுத்துங்கள்.',
    },
    'Apply Fungicide': {
      'si': 'දිලීර නාශක යොදන්න',
      'ta': 'பூஞ்சைக்கொல்லியைப் பயன்படுத்துங்கள்',
    },
    'Use copper-based or chlorothalonil fungicide every 7–10 days.': {
      'si': 'දින 7-10 කට වරක් කොපර් හෝ ක්ලෝරොතලෝනිල් දිලීර නාශක යොදන්න.',
      'ta': '7-10 நாட்களுக்கு ஒருமுறை காப்பர் பூஞ்சைக்கொல்லியைப் பயன்படுத்துங்கள்.',
    },
    'Improve Air Circulation': {
      'si': 'වාතාශ්‍රය වැඩි දියුණු කරන්න',
      'ta': 'காற்று சுழற்சியை மேம்படுத்தவும்',
    },
    'Space plants adequately. Avoid overhead irrigation.': {
      'si': 'පැල අතර නිසි පරතරයක් තබන්න. ඉහළින් ජලය යෙදීමෙන් වළකින්න.',
      'ta': 'செடிகளுக்கு போதுமான இடைவெளி விடவும். மேல் தெளிப்பு பாசனத்தைத் தவிர்க்கவும்.',
    },
    'Soil Nutrition': {
      'si': 'පස් පෝෂණය',
      'ta': 'மண் ஊட்டச்சத்து',
    },
    'Boost potassium levels to strengthen plant immunity.': {
      'si': 'ශාකයේ ප්‍රතිශක්තිය වැඩි කිරීමට පොටෑසියම් මට්ටම ඉහළ නංවන්න.',
      'ta': 'தாவர நோய் எதிர்ப்புச் சக்தியை வலுப்படுத்த பொட்டாசியம் அளவை அதிகரிக்கவும்.',
    },
    'Remove and burn infected foliage immediately': {
      'si': 'රෝගී පත්‍ර වහාම ඉවත් කර පුළුස්සා දමන්න',
      'ta': 'பாதிக்கப்பட்ட இலைகளை உடனடியாக அகற்றி எரிக்கவும்',
    },
    'Apply Copper Oxychloride 50% WP (Rs. 950 / 500g)': {
      'si': 'කොපර් ඔක්සික්ලෝරයිඩ් 50% WP යොදන්න (රු. 950 / 500g)',
      'ta': 'காப்பர் ஆக்ஸிகுளோரைடு 50% WP பயன்படுத்தவும் (ரூ. 950 / 500g)',
    },
    'Chlorothalonil 75% WP every 7–10 days (Rs. 1,450)': {
      'si': 'දින 7–10 කට වරක් ක්ලෝරොතලෝනිල් 75% WP (රු. 1,450)',
      'ta': '7-10 நாட்களுக்கு ஒருமுறை குளோரோதலோனில் 75% WP (ரூ. 1,450)',
    },
    'Ensure 60cm plant spacing for air circulation': {
      'si': 'වාතාශ්‍රය සඳහා පැල අතර 60cm පරතරයක් තබන්න',
      'ta': 'காற்று சுழற்சிக்கு 60 செ.மீ செடி இடைவெளி விடவும்',
    },
    'Destroy whole infected plants if >40% canopy affected': {
      'si': 'පැලයෙන් >40% ක් රෝගී නම් සම්පූර්ණ පැලය විනාශ කරන්න',
      'ta': '>40% பாதிக்கப்பட்டால் முழு செடிகளையும் அழிக்கவும்',
    },
    'Apply Mancozeb 80% WP protectant (Rs. 1,200 / 1kg)': {
      'si': 'මැන්කොසෙබ් 80% WP ආරක්ෂකය යොදන්න (රු. 1,200 / 1kg)',
      'ta': 'மேன்கோசெப் 80% WP பூஞ்சைக்கொல்லி (ரூ. 1,200 / 1kg)',
    },
    'Metalaxyl + Mancozeb systemic spray (Rs. 2,100 / 250g)': {
      'si': 'මෙටලැක්සිල් + මැන්කොසෙබ් ඉසින්න (රු. 2,100 / 250g)',
      'ta': 'மெட்டாலாக்சில் + மேன்கோசெப் தெளிப்பு (ரூ. 2,100 / 250g)',
    },
    'Switch strictly to drip irrigation at root level': {
      'si': 'මුල් මට්ටමට බිංදු ජල සම්පාදනය පමණක් භාවිතා කරන්න',
      'ta': 'வேர் மட்டத்தில் சொட்டு நீர் பாசனத்திற்கு மாறவும்',
    },
  };

  static String translateDisease(String name, String code) {
    if (code == 'en') return name;
    final entry = _diseaseDict[name];
    if (entry != null && entry.containsKey(code)) {
      return entry[code]!;
    }
    return name;
  }

  static String translateSymptom(String symptom, String code) {
    if (code == 'en') return symptom;
    final entry = _symptomDict[symptom];
    if (entry != null && entry.containsKey(code)) {
      return entry[code]!;
    }
    return symptom;
  }

  static String translateTreatment(String text, String code) {
    if (code == 'en') return text;
    final entry = _treatmentDict[text];
    if (entry != null && entry.containsKey(code)) {
      return entry[code]!;
    }
    return text;
  }
}
