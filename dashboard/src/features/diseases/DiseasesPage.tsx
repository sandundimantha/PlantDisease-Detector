import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Edit2, Trash2, Search, AlertCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td, Pagination } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import { formatDate } from '../../lib/utils';
import toast from 'react-hot-toast';
import type { Disease } from '../../types/database';

const PAGE_SIZE = 10;

async function fetchDiseases(page: number, search: string) {
  let query = supabase
    .from('diseases')
    .select('*', { count: 'exact' })
    .order('name_en', { ascending: true })
    .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
    
  if (search) query = query.ilike('name_en', `%${search}%`);
  const { data, count, error } = await query;
  if (error) throw error;
  return { data: (data ?? []) as Disease[], count: count ?? 0 };
}

const EMPTY_FORM: Partial<Disease> = { name_en: '', name_si: '', name_ta: '', crop: '', model_label: '', description: '' };

export function DiseasesPage() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<Disease | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Disease | null>(null);
  const [form, setForm] = useState<Partial<Disease>>(EMPTY_FORM);

  const { data, isLoading } = useQuery({ queryKey: ['diseases', page, search], queryFn: () => fetchDiseases(page, search) });

  const upsertMutation = useMutation({
    mutationFn: async (f: Partial<Disease>) => {
      if (!f.name_en?.trim() || !f.name_si?.trim() || !f.crop?.trim() || !f.model_label?.trim()) {
        throw new Error('Name (EN), Name (SI), Crop and ML Model Label are required.');
      }
      // Only send real columns of the diseases table
      const payload = {
        name_en: f.name_en.trim(),
        name_si: f.name_si.trim(),
        name_ta: f.name_ta?.trim() || null,
        crop: f.crop.trim(),
        model_label: f.model_label.trim(),
        description: f.description?.trim() || null,
        updated_at: new Date().toISOString(),
      };
      const { error } = editTarget
        ? await supabase.from('diseases').update(payload).eq('id', editTarget.id)
        : await supabase.from('diseases').insert(payload);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['diseases'] }); toast.success('Saved!'); setModalOpen(false); setEditTarget(null); setForm(EMPTY_FORM); },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from('diseases').delete().eq('id', id); if (error) throw error; },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['diseases'] }); toast.success('Deleted'); setDeleteTarget(null); },
    onError: (e: Error) => toast.error(e.message),
  });

  function set<K extends keyof Disease>(key: K, val: Disease[K]) { setForm((f) => ({ ...f, [key]: val })); }
  function openEdit(d: Disease) { setEditTarget(d); setForm({ ...d }); setModalOpen(true); }
  function openCreate() { setEditTarget(null); setForm(EMPTY_FORM); setModalOpen(true); }

  return (
    <AppLayout title="Disease Directory" subtitle="Manage known diseases and link them to the ML model output">
      <div className="flex items-center gap-3 mb-5 flex-wrap">
        <form onSubmit={(e) => { e.preventDefault(); setSearch(searchInput); setPage(1); }} className="relative flex-1 min-w-[220px] max-w-sm">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input className="lumina-input pl-9 py-2 text-[13px]" placeholder="Search diseases…" value={searchInput} onChange={(e) => { setSearchInput(e.target.value); if (!e.target.value) { setSearch(''); setPage(1); } }} />
        </form>
        <button className="btn-primary" onClick={openCreate}><Plus size={15} /> Add Disease</button>
      </div>

      <DataTable loading={isLoading} empty={!isLoading && (data?.data.length ?? 0) === 0}>
        <thead>
          <tr>
            <Th>Disease Name (EN)</Th>
            <Th>Crop</Th>
            <Th>ML Model Label</Th>
            <Th>Last Updated</Th>
            <Th>Actions</Th>
          </tr>
        </thead>
        <tbody>
          {data?.data.map((d) => (
            <tr key={d.id}>
              <Td><p className="font-semibold text-[13px]">{d.name_en}</p></Td>
              <Td><span className="text-[13px]">{d.crop}</span></Td>
              <Td><code className="px-2 py-1 bg-gray-100 rounded text-[11px] font-mono border text-emerald-700">{d.model_label}</code></Td>
              <Td><span className="text-[12px]">{formatDate(d.updated_at)}</span></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => openEdit(d)} className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-gray-100 transition-colors"><Edit2 size={14} style={{ color: 'var(--color-text-secondary)' }} /></button>
                  <button onClick={() => setDeleteTarget(d)} className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-red-50 transition-colors"><Trash2 size={14} color="#D94E4E" /></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>
      {(data?.count ?? 0) > PAGE_SIZE && <Pagination page={page} pageSize={PAGE_SIZE} total={data?.count ?? 0} onPageChange={setPage} />}

      <Modal open={modalOpen} onClose={() => { setModalOpen(false); setEditTarget(null); }} title={editTarget ? 'Edit Disease' : 'Add Disease'}>
        <div className="space-y-4">
          <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl flex items-start gap-3">
            <AlertCircle size={16} className="text-amber-600 shrink-0 mt-0.5" />
            <p className="text-[12px] text-amber-800">The <strong>Model Label</strong> must exactly match the output class name from your TFLite model's `labels.txt` file, otherwise predictions will fail.</p>
          </div>
          <div><label className="lumina-label">Name (EN) *</label><input className="lumina-input" value={form.name_en ?? ''} onChange={(e) => set('name_en', e.target.value)} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="lumina-label">Name (SI) *</label><input className="lumina-input" value={form.name_si ?? ''} onChange={(e) => set('name_si', e.target.value)} /></div>
            <div><label className="lumina-label">Name (TA)</label><input className="lumina-input" value={form.name_ta ?? ''} onChange={(e) => set('name_ta', e.target.value)} /></div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="lumina-label">Crop *</label><input className="lumina-input" value={form.crop ?? ''} onChange={(e) => set('crop', e.target.value)} placeholder="e.g. Tomato" /></div>
            <div><label className="lumina-label">ML Model Label *</label><input className="lumina-input font-mono" value={form.model_label ?? ''} onChange={(e) => set('model_label', e.target.value)} placeholder="Tomato___Bacterial_spot" /></div>
          </div>
          <div><label className="lumina-label">Description (EN)</label><textarea className="lumina-input" rows={3} value={form.description ?? ''} onChange={(e) => set('description', e.target.value)} /></div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button className="btn-secondary" onClick={() => setModalOpen(false)}>Cancel</button>
            <button className="btn-primary" onClick={() => upsertMutation.mutate(form)} disabled={upsertMutation.isPending}>{upsertMutation.isPending ? 'Saving…' : 'Save'}</button>
          </div>
        </div>
      </Modal>

      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Delete Disease?" message={`Delete "${deleteTarget?.name_en}"?`} loading={deleteMutation.isPending} />
    </AppLayout>
  );
}
