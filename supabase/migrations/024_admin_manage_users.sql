-- ════════════════════════════════════════════════════════════════════════════
-- 024 — Admin dashboard user management (found by the admin dashboard tests)
--
-- 1. profiles had no admin UPDATE policy, so the dashboard's Edit Farmer,
--    Edit Officer, Remove Officer and Create Officer (profile details) all
--    changed 0 rows and failed silently.
-- 2. Delete Farmer deleted the profiles row directly, which RLS blocked (and
--    would have left the login behind). admin_delete_user() removes a farmer's
--    data and login, like delete_my_account() does for the user themselves.
--    Officer and admin accounts cannot be deleted this way.
-- Safe to run more than once.
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Admins can update profiles" ON public.profiles;
CREATE POLICY "Admins can update profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public."current_role"() = 'admin')
  WITH CHECK (public."current_role"() = 'admin');

CREATE OR REPLACE FUNCTION public.admin_delete_user(target uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  target_role text;
begin
  if public."current_role"() is distinct from 'admin' then
    raise exception 'Only an administrator can delete users';
  end if;
  if target = auth.uid() then
    raise exception 'You cannot delete your own account here';
  end if;

  select role::text into target_role from public.profiles where id = target;
  if target_role is null then
    raise exception 'User not found';
  end if;
  if target_role in ('officer', 'admin') then
    raise exception 'Officer and admin accounts cannot be deleted. Change the role first.';
  end if;

  delete from public.scans         where user_id = target;
  delete from public.field_blocks  where user_id = target;
  delete from public.farm_tasks    where user_id = target;
  delete from public.yield_entries where user_id = target;
  delete from auth.users           where id = target;
end;
$function$;

REVOKE ALL ON FUNCTION public.admin_delete_user(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
