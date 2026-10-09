import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import { Badge } from '../../components/ui/Badge';
import { Edit2, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';

export function FeedbackPage() {
  const queryClient = useQueryClient();
  const [editTarget, setEditTarget] = useState<any>(null);
  const [deleteTarget, setDeleteTarget] = useState<any>(null);

  const { data, isLoading } = useQuery({ queryKey: ['feedback'], queryFn: async () => {
    const { data } = await supabase.from('feedback').select('*, user:user_id(full_name)').order('created_at', { ascending: false }).limit(20);
    return data ?? [];
  }});

  const updateMutation = useMutation({
    mutationFn: async (updates: any) => {
      const { error } = await supabase.from('feedback').update({ status: updates.status }).eq('id', updates.id);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['feedback'] }); setEditTarget(null); toast.success('Status updated'); },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.from('feedback').delete().eq('id', id); if (error) throw error; },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['feedback'] }); setDeleteTarget(null); toast.success('Deleted'); }
  });

  return (
    <AppLayout title="Feedback" subtitle="Manage user bug reports and feedback">
      <DataTable loading={isLoading} empty={!isLoading && data?.length === 0}>
        <thead><tr><Th>Type</Th><Th>User</Th><Th>Message</Th><Th>Status</Th><Th>Actions</Th></tr></thead>
        <tbody>
          {data?.map((f) => (
            <tr key={f.id}>
              <Td><span className="capitalize font-medium">{f.type}</span></Td>
              <Td><span className="text-gray-500">{(f as any).user?.full_name || 'Anonymous'}</span></Td>
              <Td><p className="truncate max-w-[300px]">{f.message}</p></Td>
              <Td><Badge status={f.status} /></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => setEditTarget(f)} className="p-2 hover:bg-gray-100 rounded text-gray-600"><Edit2 size={14}/></button>
                  <button onClick={() => setDeleteTarget(f)} className="p-2 hover:bg-red-50 rounded text-red-600"><Trash2 size={14}/></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>

      <Modal open={!!editTarget} onClose={() => setEditTarget(null)} title="Update Feedback Status">
        {editTarget && (
          <div className="space-y-4">
            <div>
              <label className="lumina-label">Status</label>
              <select className="lumina-input" value={editTarget.status} onChange={e => setEditTarget({ ...editTarget, status: e.target.value })}>
                <option value="open">Open</option>
                <option value="in_progress">In Progress</option>
                <option value="resolved">Resolved</option>
                <option value="wontfix">Won't Fix</option>
              </select>
            </div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <button className="btn-secondary" onClick={() => setEditTarget(null)}>Cancel</button>
              <button className="btn-primary" onClick={() => updateMutation.mutate(editTarget)} disabled={updateMutation.isPending}>Save</button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Delete Feedback?" message="Are you sure?" />
    </AppLayout>
  );
}
