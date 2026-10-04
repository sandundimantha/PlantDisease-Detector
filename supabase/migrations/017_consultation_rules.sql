-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 017: Enforce consultation rules in the database (second code
-- review of the Member D branch). The app already follows these rules; this
-- stops them being bypassed through the REST API.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Farmers may only withdraw their own request while it is still waiting
--    (pending, no officer). 009's policy let them set any status or officer.
DROP POLICY IF EXISTS "Farmers can update own consultations" ON consultations;
CREATE POLICY "Farmers can update own consultations"
  ON consultations FOR UPDATE
  USING (auth.uid() = farmer_id AND status = 'pending' AND officer_id IS NULL)
  WITH CHECK (auth.uid() = farmer_id AND status IN ('pending', 'cancelled') AND officer_id IS NULL);

-- 2. Officers may delete only closed cases (resolved / cancelled) that are
--    unassigned or their own, so a farmer's open request is never lost.
DROP POLICY IF EXISTS "Officers can delete consultations" ON consultations;
CREATE POLICY "Officers can delete consultations"
  ON consultations FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'officer')
    AND status IN ('resolved', 'cancelled')
    AND (officer_id IS NULL OR officer_id = auth.uid())
  );

-- 3. Every officer account gets a directory entry (Expert Consult / Officer
--    Map), including accounts created or promoted after migration 016.
CREATE OR REPLACE FUNCTION public.ensure_officer_directory_entry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'officer'
     AND NOT EXISTS (SELECT 1 FROM public.agri_officers WHERE profile_id = NEW.id) THEN
    INSERT INTO public.agri_officers
      (name, title, zone, phone, center, distance_km, image_url, availability,
       specializations, latitude, longitude, profile_id)
    VALUES (
      coalesce(nullif(NEW.full_name, ''), 'Agricultural Officer'),
      'Agriculture Instructor',
      coalesce(nullif(NEW.district, ''), 'Sri Lanka'),
      coalesce(NEW.phone, ''),
      coalesce(nullif(NEW.district, ''), 'District') || ' Agrarian Centre',
      0, '',
      CASE WHEN coalesce(NEW.is_on_duty, true) THEN 'On Duty' ELSE 'Off Duty' END,
      ARRAY['Crop Disease'],
      7.8731, 80.7718,  -- centre of Sri Lanka until an admin sets the real location
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_officer_directory_entry ON public.profiles;
CREATE TRIGGER trg_ensure_officer_directory_entry
  AFTER INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_officer_directory_entry();
