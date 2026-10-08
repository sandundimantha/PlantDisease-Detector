-- ════════════════════════════════════════════════════════════════════════════
-- 020 — Let users delete their own records, and report outbreaks
--
-- History (scans) and Farm (field blocks, tasks, yield) already show a swipe
-- to delete, but these tables had no DELETE policy, so RLS silently deleted
-- nothing and the rows came back on refresh.
-- Disease Radar's "report outbreak" had no INSERT policy on outbreak_reports.
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Users can delete their own scans." ON public.scans;
CREATE POLICY "Users can delete their own scans."
  ON public.scans FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own field blocks." ON public.field_blocks;
CREATE POLICY "Users can delete their own field blocks."
  ON public.field_blocks FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own tasks." ON public.farm_tasks;
CREATE POLICY "Users can delete their own tasks."
  ON public.farm_tasks FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own yield entries." ON public.yield_entries;
CREATE POLICY "Users can delete their own yield entries."
  ON public.yield_entries FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ─── Outbreak reports from the Disease Radar ───────────────────────────────
ALTER TABLE public.outbreak_reports
  ADD COLUMN IF NOT EXISTS reported_by uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

DROP POLICY IF EXISTS "Signed-in users can report outbreaks." ON public.outbreak_reports;
CREATE POLICY "Signed-in users can report outbreaks."
  ON public.outbreak_reports FOR INSERT TO authenticated
  WITH CHECK (reported_by = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own outbreak reports." ON public.outbreak_reports;
CREATE POLICY "Users can delete their own outbreak reports."
  ON public.outbreak_reports FOR DELETE TO authenticated
  USING (reported_by = auth.uid());
