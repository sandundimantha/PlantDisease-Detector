import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td, Pagination } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import { formatDate, truncate } from '../../lib/utils';
import toast from 'react-hot-toast';
import type { Disease, Treatment } from '../../types/database';

const PAGE_SIZE = 10;
const KINDS: Treatment['kind'][] = ['organic', 'chemical', 'cultural'];
const KIND_STYLE: Record<Treatment['kind'], string> = {
  organic: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  chemical: 'bg-amber-50 text-amber-700 border-amber-200',
  cultural: 'bg-sky-50 text-sky-700 border-sky-200',
};

type TreatmentRow = Treatment & { disease?: { name_en: string } | null };

async function fetchTreatments(page: number, diseaseId: string, kind: string) {
  let query = supabase
    .from('treatments')
    .select('*, disease:disease_id(name_en)', { count: 'exact' })
    .order('disease_id', { ascending: true })
    .order('sort_order', { ascending: true })
    .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
  if (diseaseId) query = query.eq('disease_id', diseaseId);
  if (kind) query = query.eq('kind', kind);
  const { data, count, error } = await query;
  if (error) throw error;
  return { data: (data ?? []) as TreatmentRow[], count: count ?? 0 };
}

async function fetchDiseaseOptions() {
  const { data, error } = await supabase.from('diseases').select('id, name_en, crop').order('name_en');
  if (error) throw error;
  return (data ?? []) as Pick<Disease, 'id' | 'name_en' | 'crop'>[];
}

const EMPTY_FORM: Partial<Treatment> = { disease_id: '', kind: 'chemical', steps_en: '', steps_si: '', steps_ta: '', precautions: '', est_cost_lkr: undefined, sort_order: 0 };

export function TreatmentsPage() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [diseaseFilter, setDiseaseFilter] = useState('');
  const [kindFilter, setKindFilter] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<TreatmentRow | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<TreatmentRow | null>(null);
  const [form, setForm] = useState<Partial<Treatment>>(EMPTY_FORM);

  const { data, isLoading } = useQuery({
    queryKey: ['treatments', page, diseaseFilter, kindFilter],
    queryFn: () => fetchTreatments(page, diseaseFilter, kindFilter),
  });
  const { data: diseases } = useQuery({ queryKey: ['disease-options'], queryFn: fetchDiseaseOptions });

  const upsertMutation = useMutation({
    mutationFn: async (f: Partial<Treatment>) => {
      if (!f.disease_id) throw new Error('Choose a disease.');
      if (!f.steps_si?.trim()) throw new Error('Steps (Sinhala) are required.');
      if (!f.steps_en?.trim()) throw new Error('Steps (English) are required.');
      const payload = {
        disease_id: f.disease_id,
        kind: f.kind ?? 'chemical',
        steps_en: f.steps_en?.trim() || null,
        steps_si: f.steps_si.trim(),
        steps_ta: f.steps_ta?.trim() || null,
        precautions: f.precautions?.trim() || null,
        est_cost_lkr: f.est_cost_lkr ?? null,
        sort_order: f.sort_order ?? 0,
        updated_at: new Date().toISOString(),
      };
      const { error } = editTarget
        ? await supabase.from('treatments').update(payload).eq('id', editTarget.id)
        : await supabase.from('treatments').insert(payload);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treatments'] });
      toast.success(editTarget ? 'Treatment updated' : 'Treatment added');
      closeModal();
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('treatments').delete().eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['treatments'] }); toast.success('Treatment deleted'); setDeleteTarget(null); },
    onError: (e: Error) => toast.error(e.message),
  });

  function set<K extends keyof Treatment>(key: K, val: Treatment[K] | undefined) { setForm((f) => ({ ...f, [key]: val })); }
  function openEdit(t: TreatmentRow) { setEditTarget(t); setForm({ ...t }); setModalOpen(true); }
  function openCreate() { setEditTarget(null); setForm({ ...EMPTY_FORM, disease_id: diseaseFilter }); setModalOpen(true); }
  function closeModal() { setModalOpen(false); setEditTarget(null); setForm(EMPTY_FORM); }

  return (
    <AppLayout title="Treatments" subtitle="Organic, chemical and cultural treatment steps for each disease">
      <div className="flex items-center gap-3 mb-5 flex-wrap">
        <select className="lumina-input py-2 text-[13px] max-w-xs" value={diseaseFilter} onChange={(e) => { setDiseaseFilter(e.target.value); setPage(1); }}>
          <option value="">All diseases</option>
          {diseases?.map((d) => <option key={d.id} value={d.id}>{d.name_en}</option>)}
        </select>
        <select className="lumina-input py-2 text-[13px] max-w-[160px]" value={kindFilter} onChange={(e) => { setKindFilter(e.target.value); setPage(1); }}>
          <option value="">All kinds</option>
          {KINDS.map((k) => <option key={k} value={k}>{k[0].toUpperCase() + k.slice(1)}</option>)}
        </select>
        <div className="flex-1" />
        <button className="btn-primary" onClick={openCreate}><Plus size={15} /> Add Treatment</button>
      </div>

      <DataTable loading={isLoading} empty={!isLoading && (data?.data.length ?? 0) === 0} emptyText="No treatments yet. Add the first one.">
        <thead>
          <tr>
            <Th>Disease</Th>
            <Th>Kind</Th>
            <Th>Steps (EN)</Th>
            <Th>Est. Cost</Th>
            <Th>Order</Th>
            <Th>Updated</Th>
            <Th>Actions</Th>
          </tr>
        </thead>
        <tbody>
          {data?.data.map((t) => (
            <tr key={t.id}>
              <Td><p className="font-semibold text-[13px]">{t.disease?.name_en ?? '—'}</p></Td>
              <Td><span className={`px-2 py-1 rounded-md border text-[11px] font-semibold capitalize ${KIND_STYLE[t.kind]}`}>{t.kind}</span></Td>
              <Td><span className="text-[12px]" title={t.steps_en ?? ''}>{truncate(t.steps_en ?? t.steps_si ?? '', 70)}</span></Td>
              <Td><span className="text-[12px]">{t.est_cost_lkr != null ? `Rs. ${Number(t.est_cost_lkr).toLocaleString()}` : '—'}</span></Td>
              <Td><span className="text-[12px]">{t.sort_order}</span></Td>
              <Td><span className="text-[12px]">{formatDate(t.updated_at)}</span></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => openEdit(t)} title="Edit" className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-gray-100 transition-colors"><Edit2 size={14} style={{ color: 'var(--color-text-secondary)' }} /></button>
                  <button onClick={() => setDeleteTarget(t)} title="Delete" className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-red-50 transition-colors"><Trash2 size={14} color="#D94E4E" /></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>
      {(data?.count ?? 0) > PAGE_SIZE && <Pagination page={page} pageSize={PAGE_SIZE} total={data?.count ?? 0} onPageChange={setPage} />}

      <Modal open={modalOpen} onClose={closeModal} title={editTarget ? 'Edit Treatment' : 'Add Treatment'} maxWidth={620}>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="lumina-label">Disease *</label>
              <select className="lumina-input" value={form.disease_id ?? ''} onChange={(e) => set('disease_id', e.target.value)}>
                <option value="">Choose a disease…</option>
                {diseases?.map((d) => <option key={d.id} value={d.id}>{d.name_en} ({d.crop})</option>)}
              </select>
            </div>
            <div>
              <label className="lumina-label">Kind *</label>
              <select className="lumina-input" value={form.kind ?? 'chemical'} onChange={(e) => set('kind', e.target.value as Treatment['kind'])}>
                {KINDS.map((k) => <option key={k} value={k}>{k[0].toUpperCase() + k.slice(1)}</option>)}
              </select>
            </div>
          </div>
          <div><label className="lumina-label">Steps (EN) *</label><textarea className="lumina-input" rows={3} value={form.steps_en ?? ''} onChange={(e) => set('steps_en', e.target.value)} placeholder="One step per line" /></div>
          <div><label className="lumina-label">Steps (SI) *</label><textarea className="lumina-input" rows={3} value={form.steps_si ?? ''} onChange={(e) => set('steps_si', e.target.value)} /></div>
          <div><label className="lumina-label">Steps (TA)</label><textarea className="lumina-input" rows={3} value={form.steps_ta ?? ''} onChange={(e) => set('steps_ta', e.target.value)} /></div>
          <div><label className="lumina-label">Precautions</label><textarea className="lumina-input" rows={2} value={form.precautions ?? ''} onChange={(e) => set('precautions', e.target.value)} placeholder="e.g. Wear gloves; 7-day pre-harvest interval" /></div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="lumina-label">Est. Cost (LKR)</label>
              <input className="lumina-input" type="number" min={0} value={form.est_cost_lkr ?? ''} onChange={(e) => set('est_cost_lkr', e.target.value === '' ? undefined : Number(e.target.value))} />
            </div>
            <div>
              <label className="lumina-label">Display Order</label>
              <input className="lumina-input" type="number" min={0} value={form.sort_order ?? 0} onChange={(e) => set('sort_order', Number(e.target.value) || 0)} />
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button className="btn-secondary" onClick={closeModal}>Cancel</button>
            <button className="btn-primary" onClick={() => upsertMutation.mutate(form)} disabled={upsertMutation.isPending}>{upsertMutation.isPending ? 'Saving…' : 'Save'}</button>
          </div>
        </div>
      </Modal>

      <ConfirmModal
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        title="Delete Treatment?"
        message={`Delete this ${deleteTarget?.kind ?? ''} treatment for "${deleteTarget?.disease?.name_en ?? 'this disease'}"? This cannot be undone.`}
        loading={deleteMutation.isPending}
      />
    </AppLayout>
  );
}
