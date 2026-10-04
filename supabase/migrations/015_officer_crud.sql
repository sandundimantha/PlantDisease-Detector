-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 015: Officer-side CRUD (Member D — AO Dashboard, Case Inbox,
-- Officer Location Map, Case Detail Review)
-- ═══════════════════════════════════════════════════════════════════════════

-- 0. Officer Location Map needs coordinates to place pins.
ALTER TABLE public.agri_officers ADD COLUMN IF NOT EXISTS latitude  double precision;
ALTER TABLE public.agri_officers ADD COLUMN IF NOT EXISTS longitude double precision;

-- Demo officers (table was empty). Coordinates are real district centres.
INSERT INTO public.agri_officers
  (name, title, zone, phone, center, distance_km, image_url, availability, specializations, latitude, longitude)
SELECT * FROM (VALUES
  ('Ofcr. Nimal Perera',      'Agriculture Instructor',  'Gampaha',      '+94 71 000 0001', 'Gampaha Agrarian Centre',      0.0, '', 'On Duty',  ARRAY['Paddy', 'Vegetables'],        7.0873, 79.9998),
  ('Ofcr. Kumari Jayasinghe', 'Plant Protection Officer','Kandy',        '+94 71 000 0002', 'Kandy Agrarian Centre',        0.0, '', 'On Duty',  ARRAY['Crop Disease', 'Tomato'],     7.2906, 80.6337),
  ('Ofcr. Ruwan Bandara',     'Agriculture Instructor',  'Kurunegala',   '+94 71 000 0003', 'Kurunegala Agrarian Centre',   0.0, '', 'Off Duty', ARRAY['Coconut', 'Paddy'],           7.4863, 80.3647),
  ('Ofcr. Fathima Rizna',     'Subject Matter Officer',  'Anuradhapura', '+94 71 000 0004', 'Anuradhapura Agrarian Centre', 0.0, '', 'On Duty',  ARRAY['Paddy', 'Pest Control'],      8.3114, 80.4037),
  ('Ofcr. Saman Kumara',      'Plant Protection Officer','Nuwara Eliya', '+94 71 000 0005', 'Nuwara Eliya Agrarian Centre', 0.0, '', 'On Duty',  ARRAY['Potato', 'Up-country Vegetables'], 6.9497, 80.7891)
) AS v(name, title, zone, phone, center, distance_km, image_url, availability, specializations, latitude, longitude)
WHERE NOT EXISTS (SELECT 1 FROM public.agri_officers);

-- 1. Field visits: scheduled by officers (AO Dashboard "Quick Action") or
--    requested by farmers (Officer Location Map "Request Visit").
CREATE TABLE IF NOT EXISTS public.officer_visits (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  officer_id       uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  agri_officer_id  uuid REFERENCES public.agri_officers(id) ON DELETE SET NULL,
  farmer_id        uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  consultation_id  uuid REFERENCES public.consultations(id) ON DELETE SET NULL,
  farmer_name      text NOT NULL,
  village          text,
  reason           text,
  scheduled_for    timestamptz,
  status           text NOT NULL DEFAULT 'requested', -- requested | scheduled | completed | cancelled
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

ALTER TABLE public.officer_visits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Officers can view all visits" ON officer_visits;
CREATE POLICY "Officers can view all visits"
  ON officer_visits FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
  );

DROP POLICY IF EXISTS "Farmers can view own visits" ON officer_visits;
CREATE POLICY "Farmers can view own visits"
  ON officer_visits FOR SELECT USING (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "Officers can schedule visits" ON officer_visits;
CREATE POLICY "Officers can schedule visits"
  ON officer_visits FOR INSERT WITH CHECK (
    auth.uid() = officer_id AND
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
  );

DROP POLICY IF EXISTS "Farmers can request visits" ON officer_visits;
CREATE POLICY "Farmers can request visits"
  ON officer_visits FOR INSERT WITH CHECK (
    auth.uid() = farmer_id AND officer_id IS NULL AND status = 'requested'
  );

DROP POLICY IF EXISTS "Officers can update visits" ON officer_visits;
CREATE POLICY "Officers can update visits"
  ON officer_visits FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
  );

DROP POLICY IF EXISTS "Officers can delete own visits" ON officer_visits;
CREATE POLICY "Officers can delete own visits"
  ON officer_visits FOR DELETE USING (auth.uid() = officer_id);

DROP POLICY IF EXISTS "Farmers can cancel own requests" ON officer_visits;
CREATE POLICY "Farmers can cancel own requests"
  ON officer_visits FOR DELETE USING (auth.uid() = farmer_id AND status = 'requested');

-- 2. AO Dashboard on-duty toggle is persisted instead of local widget state.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_on_duty boolean DEFAULT true;

-- 3. Case Inbox delete: consultations previously had no DELETE policy, so
--    deletes from the app were silently blocked by RLS.
DROP POLICY IF EXISTS "Officers can delete consultations" ON consultations;
CREATE POLICY "Officers can delete consultations"
  ON consultations FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
  );

-- 4. Realtime so a farmer's visit request appears on the officer dashboard live.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.officer_visits;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
