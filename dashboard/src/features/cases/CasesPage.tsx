import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Trash2, Edit2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td } from '../../components/ui/DataTable';
import { ConfirmModal, Modal } from '../../components/ui/Modal';
import { Badge } from '../../components/ui/Badge';
import toast from 'react-hot-toast';
import type { Consultation } from '../../types/database';

async function fetchCases(page: number) {
  const { data, count, error } = await supabase.from('consultations').select('*, farmer:farmer_id(full_name)', { count: 'exact' }).range((page - 1) * 10, page * 10 - 1);
  if (error) throw error;
  return { data: (data ?? []) as Consultation[], count: count ?? 0 };
}

export function CasesPage() {
  const queryClient = useQueryClient();
  const [page] = useState(1);
  const [editTarget, setEditTarget] = useState<Consultation | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Consultation | null>(null);

  const { data, isLoading } = useQuery({ queryKey: ['consultations', page], queryFn: () => fetchCases(page) });

  const updateMutation = useMutation({
    mutationFn: async (updates: Partial<Consultation>) => {
      const { error } = await supabase.from('consultations').update({ status: updates.status }).eq('id', updates.id);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['consultations'] }); setEditTarget(null); toast.success('Status updated'); },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from('consultations').delete().eq('id', id); if (error) throw error; },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['consultations'] }); setDeleteTarget(null); toast.success('Deleted'); },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <AppLayout title="Cases" subtitle="Manage farmer disease consultations">
      <DataTable loading={isLoading} empty={!isLoading && data?.data.length === 0}>
        <thead><tr><Th>Disease</Th><Th>Farmer</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
        <tbody>
          {data?.data.map((c) => (
            <tr key={c.id}>
              <Td><span className="font-semibold text-gray-900">{c.disease_name || 'Unknown Disease'}</span></Td>
              <Td><span className="text-gray-500">{(c as any).farmer?.full_name || 'Unknown Farmer'}</span></Td>
              <Td><Badge status={c.status || 'pending'} /></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => setEditTarget(c)} className="p-2 hover:bg-gray-100 rounded text-gray-600"><Edit2 size={14}/></button>
                  <button onClick={() => setDeleteTarget(c)} className="p-2 hover:bg-red-50 rounded text-red-600"><Trash2 size={14}/></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>

      <Modal open={!!editTarget} onClose={() => setEditTarget(null)} title="Update Case Status">
        {editTarget && (
          <div className="space-y-4">
            <div>
              <label className="lumina-label">Status</label>
              <select className="lumina-input" defaultValue={editTarget.status} onChange={e => editTarget.status = e.target.value as any}>
                <option value="pending">Pending</option>
                <option value="in_progress">In Progress</option>
                <option value="resolved">Resolved</option>
              </select>
            </div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <button className="btn-secondary" onClick={() => setEditTarget(null)}>Cancel</button>
              <button className="btn-primary" onClick={() => updateMutation.mutate(editTarget)} disabled={updateMutation.isPending}>Save</button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Delete Case?" message="Are you sure you want to delete this case?" />
    </AppLayout>
  );
}
