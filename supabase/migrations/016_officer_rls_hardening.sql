-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 016: Tighten officer permissions and link officer accounts to the
-- public officer directory (code review fixes for migration 015).
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Link directory entries (agri_officers) to officer login accounts so a
--    farmer's choice of officer and the officer's on-duty status mean something.
ALTER TABLE public.agri_officers
  ADD COLUMN IF NOT EXISTS profile_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Every officer account without a directory entry gets one (demo: the
-- officer@gmail.com account, placed at its profile district).
INSERT INTO public.agri_officers
  (name, title, zone, phone, center, distance_km, image_url, availability,
   specializations, latitude, longitude, profile_id)
SELECT
  coalesce(nullif(p.full_name, ''), 'Agricultural Officer'),
  'Agriculture Instructor',
  coalesce(nullif(p.district, ''), 'Nuwara Eliya'),
  coalesce(p.phone, ''),
  coalesce(nullif(p.district, ''), 'Nuwara Eliya') || ' Agrarian Centre',
  0, '',
  CASE WHEN coalesce(p.is_on_duty, true) THEN 'On Duty' ELSE 'Off Duty' END,
  ARRAY['Crop Disease', 'Vegetables'],
  6.9708, 80.7829,
  p.id
FROM public.profiles p
WHERE p.role = 'officer'
  AND NOT EXISTS (SELECT 1 FROM public.agri_officers a WHERE a.profile_id = p.id);

-- 2. AO Dashboard Online/Offline (profiles.is_on_duty) drives the
--    availability farmers see on Expert Consult and the Officer Map.
CREATE OR REPLACE FUNCTION public.sync_officer_availability()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.agri_officers
     SET availability = CASE WHEN NEW.is_on_duty THEN 'On Duty' ELSE 'Off Duty' END
   WHERE profile_id = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_officer_availability ON public.profiles;
CREATE TRIGGER trg_sync_officer_availability
  AFTER UPDATE OF is_on_duty ON public.profiles
  FOR EACH ROW
  WHEN (OLD.is_on_duty IS DISTINCT FROM NEW.is_on_duty)
  EXECUTE FUNCTION public.sync_officer_availability();

-- 3. officer_visits: an officer may change only their own visits, or claim an
--    open farmer request addressed to them (or to an unlinked directory entry).
--    Previously any officer could update any visit, to any values.
DROP POLICY IF EXISTS "Officers can update visits" ON officer_visits;
DROP POLICY IF EXISTS "Officers update own visits or claim requests" ON officer_visits;
CREATE POLICY "Officers update own visits or claim requests"
  ON officer_visits FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
    AND (
      officer_id = auth.uid()
      OR (
        status = 'requested' AND officer_id IS NULL
        AND (
          agri_officer_id IS NULL
          OR EXISTS (
            SELECT 1 FROM public.agri_officers a
            WHERE a.id = agri_officer_id
              AND (a.profile_id IS NULL OR a.profile_id = auth.uid())
          )
        )
      )
    )
  )
  WITH CHECK (officer_id = auth.uid());

-- 4. consultations: officers may update / delete only unassigned cases or
--    their own. Previously any officer could change or delete any case,
--    including another officer's (deleting also removes the chat history).
DROP POLICY IF EXISTS "Officers can update consultations" ON consultations;
CREATE POLICY "Officers can update consultations"
  ON consultations FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
    AND (officer_id IS NULL OR officer_id = auth.uid())
  )
  WITH CHECK (officer_id = auth.uid());

DROP POLICY IF EXISTS "Officers can delete consultations" ON consultations;
CREATE POLICY "Officers can delete consultations"
  ON consultations FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
    AND (officer_id IS NULL OR officer_id = auth.uid())
  );
