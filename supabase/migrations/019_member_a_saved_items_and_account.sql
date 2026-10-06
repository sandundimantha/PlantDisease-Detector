-- ════════════════════════════════════════════════════════════════════════════
-- 019 — Member A (IT23836518): Saved Items CRUD + account language & deletion
--
-- Scenario 1 (My Account & Language):
--   C  sign-up stores the chosen language (+ district) on the new profile
--   R  app reads profiles.preferred_lang on login
--   U  changing language updates profiles.preferred_lang
--   D  delete_my_account() removes the signed-in user's account
-- Scenario 2 (Saved Items):
--   saved_items table with owner-only RLS for create / read / update / delete
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1. Language preference ────────────────────────────────────────────────
-- The column already exists (default 'si') but nothing ever wrote to it, so
-- every row holds the default. The app's own default is English; align both
-- so existing users are not switched to Sinhala on their next login.
ALTER TABLE public.profiles ALTER COLUMN preferred_lang SET DEFAULT 'en';
UPDATE public.profiles SET preferred_lang = 'en' WHERE preferred_lang = 'si';

-- Sign-up already sends full_name, district and now preferred_lang as user
-- metadata; previously only full_name was copied onto the profile.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  lang text := new.raw_user_meta_data->>'preferred_lang';
begin
  insert into public.profiles (id, full_name, phone, district, preferred_lang)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.phone,
    nullif(new.raw_user_meta_data->>'district', ''),
    case when lang in ('en', 'si', 'ta') then lang else 'en' end
  );
  return new;
end;
$function$;

-- ─── 2. Saved Items ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.saved_items (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  -- The saved scan; title/subtitle are a snapshot so the item survives if the
  -- scan itself is later removed from history.
  scan_id     uuid REFERENCES public.scans(id) ON DELETE SET NULL,
  title       text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120),
  subtitle    text,
  note        text CHECK (note IS NULL OR char_length(note) <= 500),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, scan_id)
);

CREATE INDEX IF NOT EXISTS saved_items_user_created_idx
  ON public.saved_items (user_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.saved_items_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

DROP TRIGGER IF EXISTS saved_items_touch_updated_at ON public.saved_items;
CREATE TRIGGER saved_items_touch_updated_at
  BEFORE UPDATE ON public.saved_items
  FOR EACH ROW EXECUTE FUNCTION public.saved_items_touch_updated_at();

ALTER TABLE public.saved_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own saved items" ON public.saved_items;
CREATE POLICY "Users read own saved items"
  ON public.saved_items FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users create own saved items" ON public.saved_items;
CREATE POLICY "Users create own saved items"
  ON public.saved_items FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users update own saved items" ON public.saved_items;
CREATE POLICY "Users update own saved items"
  ON public.saved_items FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users delete own saved items" ON public.saved_items;
CREATE POLICY "Users delete own saved items"
  ON public.saved_items FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- ─── 3. Delete my account ──────────────────────────────────────────────────
-- Deletes the caller's auth user; profiles and everything that references
-- profiles with ON DELETE CASCADE go with it. Tables that point at auth.users
-- without a cascade are cleared first. Officer/admin accounts are excluded:
-- they own case data other users depend on and are managed by the admin.
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  uid uuid := auth.uid();
  user_role_value text;
begin
  if uid is null then
    raise exception 'Not signed in';
  end if;

  select role::text into user_role_value from public.profiles where id = uid;
  if user_role_value in ('officer', 'admin') then
    raise exception 'Officer and admin accounts cannot be deleted from the app';
  end if;

  delete from public.scans         where user_id = uid;
  delete from public.field_blocks  where user_id = uid;
  delete from public.farm_tasks    where user_id = uid;
  delete from public.yield_entries where user_id = uid;
  delete from auth.users           where id = uid;
end;
$function$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
