-- ════════════════════════════════════════════════════════════════════════════
-- 023 — Found by the backend security tests (2026-10-10)
--
-- 1. profiles: "Public profiles are viewable by everyone" let anyone holding the
--    app's public key (it ships inside the APK) read every user's name, email,
--    phone and district without logging in. Profiles are now readable by
--    signed-in users only (community and consultation screens show names).
-- 2. community_posts: the app has Edit and Delete on your own post, but there
--    were no UPDATE/DELETE policies, so both failed silently and the post came
--    back on refresh. Owners can now edit and delete their own posts
--    (comments and likes are removed with the post by ON DELETE CASCADE).
-- Safe to run more than once.
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Signed-in users can view profiles" ON public.profiles;
CREATE POLICY "Signed-in users can view profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update their own posts" ON public.community_posts;
CREATE POLICY "Users can update their own posts"
  ON public.community_posts FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own posts" ON public.community_posts;
CREATE POLICY "Users can delete their own posts"
  ON public.community_posts FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
