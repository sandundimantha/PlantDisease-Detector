import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import { Badge } from '../../components/ui/Badge';
import toast from 'react-hot-toast';
import type { Announcement } from '../../types/database';

const PAGE_SIZE = 10;

async function fetchAnnouncements(page: number) {
  const { data, count, error } = await supabase.from('announcements').select('*', { count: 'exact' }).order('created_at', { ascending: false }).range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
  if (error) throw error;
  return { data: (data ?? []) as Announcement[], count: count ?? 0 };
}

export function AnnouncementsPage() {
  const queryClient = useQueryClient();
  const [page] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<Announcement | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Announcement | null>(null);

  const { data, isLoading } = useQuery({ queryKey: ['announcements', page], queryFn: () => fetchAnnouncements(page) });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from('announcements').delete().eq('id', id); if (error) throw error; },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['announcements'] }); setDeleteTarget(null); }
  });

  const EMPTY_FORM: Partial<Announcement> = { title: '', body: '', category: 'General', target_role: 'all', is_published: false };
  const [form, setForm] = useState<Partial<Announcement>>(EMPTY_FORM);

  const upsertMutation = useMutation({
    mutationFn: async (payload: Partial<Announcement>) => {
      if (editTarget) {
        const { error } = await supabase.from('announcements').update(payload).eq('id', editTarget.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('announcements').insert(payload);
        if (error) throw error;
      }
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['announcements'] }); setModalOpen(false); setEditTarget(null); toast.success('Saved!'); }
  });

  return (
    <AppLayout title="Announcements" subtitle="Broadcast updates to farmers and officers">
      <div className="mb-4"><button className="btn-primary" onClick={() => { setEditTarget(null); setForm(EMPTY_FORM); setModalOpen(true); }}><Plus size={14}/> Add Announcement</button></div>
      <DataTable loading={isLoading} empty={!isLoading && data?.data.length === 0}>
        <thead><tr><Th>Title</Th><Th>Category</Th><Th>Target</Th><Th>Published</Th><Th>Actions</Th></tr></thead>
        <tbody>
          {data?.data.map((a) => (
            <tr key={a.id}>
              <Td>{a.title}</Td><Td>{a.category}</Td><Td><span className="capitalize">{a.target_role}</span></Td><Td><Badge status={a.is_published ? 'active' : 'pending'} /></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => { setEditTarget(a); setForm(a); setModalOpen(true); }} className="p-2 hover:bg-gray-100 rounded"><Edit2 size={14}/></button>
                  <button onClick={() => setDeleteTarget(a)} className="p-2 hover:bg-red-50 rounded"><Trash2 size={14} color="#D94E4E"/></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>
      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Delete?" message="Delete announcement?" />
      
      <Modal open={modalOpen} onClose={() => { setModalOpen(false); setEditTarget(null); }} title={editTarget ? 'Edit Announcement' : 'New Announcement'}>
        <div className="space-y-4">
          <div><label className="lumina-label">Title</label><input className="lumina-input" value={form.title} onChange={e => setForm({...form, title: e.target.value})} /></div>
          <div><label className="lumina-label">Message Body</label><textarea className="lumina-input" rows={4} value={form.body} onChange={e => setForm({...form, body: e.target.value})} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="lumina-label">Category</label>
              <select className="lumina-input" value={form.category} onChange={e => setForm({...form, category: e.target.value})}>
                <option>General</option><option>Alert</option><option>System</option>
              </select>
            </div>
            <div>
              <label className="lumina-label">Target Audience</label>
              <select className="lumina-input" value={form.target_role} onChange={e => setForm({...form, target_role: e.target.value})}>
                <option value="all">Everyone</option><option value="farmer">Farmers Only</option><option value="officer">Officers Only</option>
              </select>
            </div>
          </div>
          <div className="flex items-center gap-2 pt-2">
            <input type="checkbox" id="pub" checked={form.is_published} onChange={e => setForm({...form, is_published: e.target.checked, published_at: e.target.checked ? new Date().toISOString() : undefined})} />
            <label htmlFor="pub" className="text-[13px] font-medium">Publish immediately</label>
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button className="btn-secondary" onClick={() => setModalOpen(false)}>Cancel</button>
            <button className="btn-primary" onClick={() => upsertMutation.mutate(form)}>Save</button>
          </div>
        </div>
      </Modal>
    </AppLayout>
  );
}
