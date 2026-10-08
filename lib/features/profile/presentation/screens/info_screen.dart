import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plant_disease_detector/core/theme/app_theme.dart';
import 'package:plant_disease_detector/core/localization/app_strings.dart';
import 'package:plant_disease_detector/core/widgets/language_selector_button.dart';
import 'package:plant_disease_detector/shared/widgets/premium_app_bar.dart';

enum InfoPage { help, privacy, terms }

/// Department of Agriculture farmer advisory line ("Govi Sahana Sarana").
const String agricultureHotline = '1920';

Future<void> callAgricultureHotline(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr(
    en: 'Could not open the phone app. Dial $agricultureHotline for the agriculture advisory line.',
    si: 'දුරකථන යෙදුම විවෘත කළ නොහැක. කෘෂිකර්ම උපදේශන සේවාව සඳහා $agricultureHotline අමතන්න.',
    ta: 'தொலைபேசி பயன்பாட்டைத் திறக்க முடியவில்லை. வேளாண் ஆலோசனைக்கு $agricultureHotline ஐ அழைக்கவும்.',
  );
  final ok = await launchUrl(Uri(scheme: 'tel', path: agricultureHotline));
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

/// Help Center, Privacy Policy and Terms of Service.
class InfoScreen extends StatelessWidget {
  final InfoPage page;
  const InfoScreen({super.key, required this.page});

  String _title(BuildContext context) => switch (page) {
        InfoPage.help => context.tr(en: 'Help Center', si: 'උපකාරක මධ්‍යස්ථානය', ta: 'உதவி மையம்'),
        InfoPage.privacy => context.tr(en: 'Privacy Policy', si: 'රහස්‍යතා ප්‍රතිපත්තිය', ta: 'தனியுரிமைக் கொள்கை'),
        InfoPage.terms => context.tr(en: 'Terms of Service', si: 'සේවා කොන්දේසි', ta: 'சேவை விதிமுறைகள்'),
      };

  List<_Section> _sections(BuildContext context) {
    _Section s(String en, String si, String ta, String ben, String bsi, String bta) =>
        _Section(context.tr(en: en, si: si, ta: ta), context.tr(en: ben, si: bsi, ta: bta));
    switch (page) {
      case InfoPage.help:
        return [
          s('How do I scan a leaf?', 'කොළයක් ස්කෑන් කරන්නේ කෙසේද?', 'இலையை எப்படி ஸ்கேன் செய்வது?',
              'Tap the Scan button, hold the phone 20–30 cm from one affected leaf in daylight, and take the photo. You can also choose a photo from your gallery.',
              'ස්කෑන් බොත්තම ඔබා, දිවා ආලෝකයේ රෝගී කොළයකින් සෙ.මී. 20–30 ක් දුරින් දුරකථනය තබා ඡායාරූපය ගන්න. ගැලරියෙන් ඡායාරූපයක් තෝරා ගැනීමටද හැකිය.',
              'ஸ்கேன் பொத்தானைத் தட்டி, பகல் வெளிச்சத்தில் பாதிக்கப்பட்ட ஒரு இலையிலிருந்து 20–30 செ.மீ தூரத்தில் படம் எடுக்கவும். கேலரியிலிருந்தும் படத்தைத் தேர்வு செய்யலாம்.'),
          s('What does the confidence score mean?', 'නිශ්චිතභාවය යනු කුමක්ද?', 'நம்பகத்தன்மை மதிப்பெண் என்றால் என்ன?',
              '70% or more: the result is reliable. 40–70%: the result is uncertain, so compare the symptoms or ask an officer. Below 40%: the app could not identify the leaf — retake the photo.',
              '70% හෝ ඊට වැඩි: ප්‍රතිඵලය විශ්වාසදායකයි. 40–70%: අවිනිශ්චිතයි, රෝග ලක්ෂණ සසඳා බලන්න හෝ නිලධාරියෙකුගෙන් විමසන්න. 40% ට අඩු: කොළය හඳුනාගත නොහැකි විය — නැවත ඡායාරූප ගන්න.',
              '70% அல்லது அதற்கு மேல்: முடிவு நம்பகமானது. 40–70%: உறுதியற்றது, அறிகுறிகளை ஒப்பிடவும் அல்லது அலுவலரிடம் கேட்கவும். 40% க்கு கீழ்: இலையை அடையாளம் காண முடியவில்லை — மீண்டும் படம் எடுக்கவும்.'),
          s('Does the app work without internet?', 'අන්තර්ජාලය නැතිව යෙදුම ක්‍රියා කරයිද?', 'இணையம் இல்லாமல் பயன்பாடு வேலை செய்யுமா?',
              'Yes. Scanning runs on your phone. Results are saved on the phone and upload automatically when you are back online. See Profile → Offline & Sync.',
              'ඔව්. ස්කෑන් කිරීම ඔබේ දුරකථනයේම සිදු වේ. ප්‍රතිඵල දුරකථනයේ සුරැකෙන අතර නැවත අන්තර්ජාලයට සම්බන්ධ වූ විට ස්වයංක්‍රීයව යවනු ලැබේ.',
              'ஆம். ஸ்கேனிங் உங்கள் தொலைபேசியிலேயே நடக்கிறது. முடிவுகள் சேமிக்கப்பட்டு, இணையம் திரும்பியதும் தானாகப் பதிவேற்றப்படும்.'),
          s('How do I talk to an officer?', 'නිලධාරියෙකු සමඟ කතා කරන්නේ කෙසේද?', 'அலுவலருடன் எப்படிப் பேசுவது?',
              'Open Home → Expert Help, choose an officer and send your problem. You will see their reply in the chat. For urgent help call the agriculture advisory line $agricultureHotline.',
              'මුල් පිටුව → විශේෂඥ සහය විවෘත කර නිලධාරියෙකු තෝරා ඔබේ ගැටලුව යවන්න. පිළිතුර චැට් එකේ දිස්වේ. හදිසි උපකාර සඳහා කෘෂිකර්ම උපදේශන අංකය $agricultureHotline අමතන්න.',
              'முகப்பு → நிபுணர் உதவி திறந்து, ஒரு அலுவலரைத் தேர்வு செய்து உங்கள் பிரச்சினையை அனுப்பவும். அவசர உதவிக்கு $agricultureHotline ஐ அழைக்கவும்.'),
          s('Which crops can the app check?', 'යෙදුමට පරීක්ෂා කළ හැකි බෝග මොනවාද?', 'எந்தப் பயிர்களைச் சரிபார்க்க முடியும்?',
              'Tomato, potato, corn (maize), pepper, apple, grape, cherry, peach, orange, squash, strawberry, blueberry, raspberry and soybean — 38 diseases and healthy leaves.',
              'තක්කාලි, අර්තාපල්, ඉරිඟු, මාළු මිරිස්, ඇපල්, මිදි, චෙරි, පීච්, දොඩම්, වට්ටක්කා, ස්ට්‍රෝබෙරි, බ්ලූබෙරි, රාස්බෙරි සහ සෝයා — රෝග සහ නිරෝගී කොළ 38 ක්.',
              'தக்காளி, உருளைக்கிழங்கு, சோளம், குடைமிளகாய், ஆப்பிள், திராட்சை, செர்ரி, பீச், ஆரஞ்சு, பூசணி, ஸ்ட்ராபெர்ரி, புளூபெர்ரி, ராஸ்பெர்ரி, சோயா — 38 வகைகள்.'),
        ];
      case InfoPage.privacy:
        return [
          s('What we collect', 'අප එකතු කරන දේ', 'நாங்கள் சேகரிப்பவை',
              'Your name, email, district and the language you choose; your scan results, saved items, farm records and messages with officers. Your location is used on the phone for weather and nearby officers.',
              'ඔබේ නම, විද්‍යුත් තැපෑල, දිස්ත්‍රික්කය සහ භාෂාව; ස්කෑන් ප්‍රතිඵල, සුරැකි අයිතම, ගොවි වාර්තා සහ නිලධාරීන් සමඟ පණිවිඩ. ස්ථානය කාලගුණය සහ ළඟම නිලධාරීන් සඳහා භාවිතා වේ.',
              'உங்கள் பெயர், மின்னஞ்சல், மாவட்டம், மொழி; ஸ்கேன் முடிவுகள், சேமித்தவை, பண்ணைப் பதிவுகள், அலுவலர்களுடனான செய்திகள். இருப்பிடம் வானிலை மற்றும் அருகிலுள்ள அலுவலர்களுக்குப் பயன்படுகிறது.'),
          s('Who can see your data', 'ඔබේ දත්ත දැකිය හැක්කේ කාටද', 'உங்கள் தரவை யார் பார்க்கலாம்',
              'Only you can see your scans, saved items and farm records. An officer sees a consultation only when you send it to them. Community posts are visible to all users.',
              'ඔබේ ස්කෑන්, සුරැකි අයිතම සහ ගොවි වාර්තා දැකිය හැක්කේ ඔබට පමණි. ඔබ නිලධාරියෙකුට යවන උපදේශනය පමණක් ඔහුට පෙනේ. ප්‍රජා පළකිරීම් සියලු දෙනාට පෙනේ.',
              'உங்கள் ஸ்கேன்கள், சேமித்தவை, பண்ணைப் பதிவுகளை நீங்கள் மட்டுமே பார்க்க முடியும். நீங்கள் அனுப்பும் ஆலோசனையை மட்டுமே அலுவலர் பார்ப்பார். சமூக இடுகைகள் அனைவருக்கும் தெரியும்.'),
          s('Your choices', 'ඔබේ තේරීම්', 'உங்கள் தேர்வுகள்',
              'You can turn off notifications and location in Profile, edit your details in Edit Profile, and delete your account and all its data from Profile → Delete Account.',
              'පැතිකඩ තුළ දැනුම්දීම් සහ ස්ථානය අක්‍රිය කළ හැක, විස්තර සංස්කරණය කළ හැක, සහ පැතිකඩ → ගිණුම මකන්න මගින් ගිණුම සහ සියලු දත්ත මැකිය හැක.',
              'சுயவிவரத்தில் அறிவிப்புகள் மற்றும் இருப்பிடத்தை முடக்கலாம், விவரங்களைத் திருத்தலாம், சுயவிவரம் → கணக்கை நீக்கு மூலம் அனைத்து தரவையும் நீக்கலாம்.'),
        ];
      case InfoPage.terms:
        return [
          s('Advice, not a guarantee', 'උපදෙස් පමණි, සහතිකයක් නොවේ', 'ஆலோசனை மட்டுமே, உத்தரவாதம் அல்ல',
              'Lumina uses an AI model to suggest a likely disease. It can be wrong. Check the symptoms and confirm with an agricultural officer before spending money on chemicals.',
              'Lumina AI ආකෘතියක් භාවිතා කර රෝගයක් යෝජනා කරයි. එය වැරදි විය හැක. රසායන සඳහා මුදල් වියදම් කිරීමට පෙර රෝග ලක්ෂණ පරීක්ෂා කර නිලධාරියෙකුගෙන් තහවුරු කරගන්න.',
              'Lumina ஒரு AI மாதிரியைப் பயன்படுத்தி நோயைப் பரிந்துரைக்கிறது. அது தவறாக இருக்கலாம். இரசாயனங்களுக்குச் செலவிடும் முன் அலுவலரிடம் உறுதிப்படுத்தவும்.'),
          s('Using chemicals safely', 'රසායන ආරක්ෂිතව භාවිතය', 'இரசாயனங்களைப் பாதுகாப்பாகப் பயன்படுத்துதல்',
              'Always follow the dose and waiting period on the product label and wear gloves and a mask when spraying.',
              'නිෂ්පාදන ලේබලයේ මාත්‍රාව සහ පොරොත්තු කාලය සැමවිටම අනුගමනය කර, ඉසීමේදී අත්වැසුම් සහ මුහුණු ආවරණ පළඳින්න.',
              'தயாரிப்பு லேபிளில் உள்ள அளவையும் காத்திருப்பு காலத்தையும் பின்பற்றி, தெளிக்கும்போது கையுறை மற்றும் முகக்கவசம் அணியவும்.'),
          s('Community rules', 'ප්‍රජා නීති', 'சமூக விதிகள்',
              'Be respectful, share only true farming information, and do not post other people\'s personal details. Posts that break these rules may be removed.',
              'ගෞරවයෙන් කටයුතු කරන්න, සත්‍ය ගොවි තොරතුරු පමණක් බෙදාගන්න, අන් අයගේ පුද්ගලික තොරතුරු පළ නොකරන්න.',
              'மரியாதையாக இருங்கள், உண்மையான விவசாயத் தகவல்களை மட்டும் பகிருங்கள், பிறரின் தனிப்பட்ட விவரங்களை இடுகையிட வேண்டாம்.'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(
        title: Text(_title(context)),
        actions: const [LanguageSelectorButton(isCompact: true)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(section.body, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                ],
              ),
            ),
          if (page == InfoPage.help) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => callAgricultureHotline(context),
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              label: Text(
                context.tr(en: 'Call advisory line $agricultureHotline', si: 'උපදේශන අංකය $agricultureHotline අමතන්න', ta: 'ஆலோசனை எண் $agricultureHotline ஐ அழைக்கவும்'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
