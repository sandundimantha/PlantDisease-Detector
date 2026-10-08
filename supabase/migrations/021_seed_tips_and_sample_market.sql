-- ════════════════════════════════════════════════════════════════════════════
-- 021 — Content for screens that were empty
--
-- tips:           farming tips shown in Home → Farming Tips (English + Sinhala)
-- markets/prices: one SAMPLE price list so the market card on the scan result
--                 can be demonstrated. It is labelled "Sample prices – not live"
--                 in the data itself; replace it with real figures when a price
--                 source is connected.
-- Safe to run more than once (skips rows that already exist).
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO public.tips (id, crop, season, title_en, body_en, title_si, body_si, published_at)
SELECT gen_random_uuid(), t.crop, t.season, t.title_en, t.body_en, t.title_si, t.body_si, now() - (t.days_ago || ' days')::interval
FROM (VALUES
  ('Tomato', 'Yala',
   'Stake tomatoes to stop leaf diseases',
   'Tie plants to stakes 30 cm above the ground. Leaves that touch wet soil pick up early blight and bacterial spot. Remove the lowest leaves once the plant is knee-high.',
   'කොළ රෝග වැළැක්වීමට තක්කාලි කණු ගසන්න',
   'පැල පොළොවෙන් සෙ.මී. 30 ක් ඉහළින් කණුවලට බඳින්න. තෙත් පසට ගැටෙන කොළවලට මුල් අංගමාරය සහ බැක්ටීරියා ලප වැළඳේ. පැලය දණහිස උසට ආ විට පහළම කොළ ඉවත් කරන්න.',
   1),
  ('Paddy', 'Maha',
   'Prepare paddy fields before the Maha rains',
   'Plough and level the field two weeks before sowing so weeds sprout and can be removed. Use certified seed paddy and soak it for 24 hours before broadcasting.',
   'මහ වැස්සට පෙර කුඹුරු සකස් කරන්න',
   'වැපිරීමට සති දෙකකට පෙර කුඹුර සී සා සමතලා කරන්න. එවිට වල් පැළ මතු වී ඉවත් කළ හැක. සහතික කළ බිත්තර වී භාවිතා කර පැය 24 ක් පොඟවා වපුරන්න.',
   3),
  ('Chilli', 'Yala',
   'Control whiteflies to protect chilli from leaf curl',
   'Leaf curl virus is spread by whiteflies. Hang yellow sticky traps, remove curled plants early, and spray neem extract on the underside of leaves every week.',
   'කොළ කොඩවීමෙන් මිරිස් ආරක්ෂා කිරීමට සුදු මැස්සන් පාලනය කරන්න',
   'කොළ කොඩවීමේ වෛරසය සුදු මැස්සන් මගින් පැතිරේ. කහ ඇලෙන උගුල් එල්ලන්න, කොඩවූ පැල කලින් ඉවත් කරන්න, සතිපතා කොළ යට කොහොඹ සාරය ඉසින්න.',
   5),
  ('All crops', 'Any',
   'Spray in the early morning, not at midday',
   'Spray between 6 and 9 am when the wind is calm. Midday sun dries the spray before it works and can burn leaves. Always wear gloves and a mask.',
   'මධ්‍යාහ්නයේ නොව උදෑසන ඉසින්න',
   'සුළඟ නිසල පෙ.ව. 6 සිට 9 දක්වා ඉසින්න. මධ්‍යාහ්න හිරු එළිය බෙහෙත ක්‍රියා කිරීමට පෙර වියළා කොළ පිළිස්සිය හැක. සැමවිටම අත්වැසුම් සහ මුහුණු ආවරණ පළඳින්න.',
   7),
  ('Potato', 'Maha',
   'Watch potatoes closely in cool, wet weather',
   'Late blight spreads in days when nights are cool and misty. Check plants every morning and start protective mancozeb sprays before the disease appears.',
   'සිසිල්, තෙත් කාලගුණයේදී අර්තාපල් හොඳින් බලන්න',
   'රාත්‍රී සිසිල් හා මීදුම සහිත විට පසු අංගමාරය දින කිහිපයකින් පැතිරේ. සෑම උදෑසනම පැල පරීක්ෂා කර රෝගය පෙනීමට පෙර මැන්කොසෙබ් ආරක්ෂක ඉසීම ආරම්භ කරන්න.',
   9),
  ('All crops', 'Any',
   'Add compost to keep soil healthy',
   'Mix 5–10 kg of well-rotted compost per square metre before planting. Healthy soil holds water in dry weeks and helps plants resist disease.',
   'පස නිරෝගීව තබා ගැනීමට කොම්පෝස්ට් යොදන්න',
   'සිටුවීමට පෙර වර්ග මීටරයකට හොඳින් දිරාපත් වූ කොම්පෝස්ට් කි.ග්‍රෑ. 5–10 ක් මිශ්‍ර කරන්න. නිරෝගී පස වියළි සතිවල ජලය රඳවා ගන්නා අතර පැලවලට රෝගවලට ඔරොත්තු දීමට උදව් කරයි.',
   12)
) AS t(crop, season, title_en, body_en, title_si, body_si, days_ago)
WHERE NOT EXISTS (SELECT 1 FROM public.tips x WHERE x.title_en = t.title_en);

-- ─── Sample market price list (clearly marked as not live) ─────────────────
INSERT INTO public.markets (id, name, distance_km, last_updated)
SELECT 'b6a1c0de-5a3f-4c2e-9f00-000000000021'::uuid, 'Dambulla Economic Centre', 0, 'Sample prices – not live'
WHERE NOT EXISTS (SELECT 1 FROM public.markets WHERE id = 'b6a1c0de-5a3f-4c2e-9f00-000000000021');

INSERT INTO public.market_prices (id, market_id, crop_name, emoji, price_per_kg, change_percent, is_best_price)
SELECT gen_random_uuid(), 'b6a1c0de-5a3f-4c2e-9f00-000000000021'::uuid, p.crop, p.emoji, p.price, p.change, p.best
FROM (VALUES
  ('Tomato', '🍅', 180::real, 4.5::real, false),
  ('Potato', '🥔', 260::real, -2.0::real, false),
  ('Green Chilli', '🌶️', 420::real, 8.0::real, true),
  ('Carrot', '🥕', 240::real, 1.5::real, false)
) AS p(crop, emoji, price, change, best)
WHERE NOT EXISTS (SELECT 1 FROM public.market_prices WHERE market_id = 'b6a1c0de-5a3f-4c2e-9f00-000000000021');
