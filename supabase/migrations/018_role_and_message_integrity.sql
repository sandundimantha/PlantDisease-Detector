-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 018: Role and message integrity (third code review of the
-- Member D branch). Both holes predate this branch, but officer routing and
-- officer RLS now rely on profiles.role, so they matter more.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Users cannot change their own role. The policy "Users can update own
--    profile." has no WITH CHECK, and permissive policies are OR'ed, so a
--    farmer could PATCH role='officer'. Only admins (or server-side SQL with
--    no JWT user) may change roles.
CREATE OR REPLACE FUNCTION public.prevent_role_self_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role
     AND auth.uid() IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only an administrator can change a user role'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_role_self_change ON public.profiles;
CREATE TRIGGER trg_prevent_role_self_change
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_role_self_change();

-- 2. sender_role comes from the sender's real profile, never from the client,
--    so a farmer cannot post a message labelled as officer advice.
CREATE OR REPLACE FUNCTION public.set_message_sender_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.sender_role := CASE
    WHEN EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.sender_id AND role = 'officer')
      THEN 'officer'
    ELSE 'farmer'
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_message_sender_role ON public.consultation_messages;
CREATE TRIGGER trg_set_message_sender_role
  BEFORE INSERT ON public.consultation_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.set_message_sender_role();

-- 3. Directory entries follow role changes both ways: a demoted officer's
--    entry is unlinked and shown Off Duty, so requests to it can be taken by
--    any officer instead of waiting forever.
CREATE OR REPLACE FUNCTION public.ensure_officer_directory_entry()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role = 'officer' THEN
    IF NOT EXISTS (SELECT 1 FROM public.agri_officers WHERE profile_id = NEW.id) THEN
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
  ELSIF TG_OP = 'UPDATE' AND OLD.role = 'officer' THEN
    UPDATE public.agri_officers
       SET profile_id = NULL, availability = 'Off Duty'
     WHERE profile_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;
