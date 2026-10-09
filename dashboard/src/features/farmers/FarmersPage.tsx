import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td, Pagination } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import toast from 'react-hot-toast';
import type { Profile } from '../../types/database';

const PAGE_SIZE = 12;

async function fetchFarmers(page: number) {
  const { data, count, error } = await supabase.from('profiles').select('*', { count: 'exact' }).eq('role', 'farmer').range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
  if (error) throw error;
  return { data: (data ?? []) as Profile[], count: count ?? 0 };
}

export function FarmersPage() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<Profile | null>(null);
  const [editTarget, setEditTarget] = useState<Profile | null>(null);

  const { data, isLoading } = useQuery({ queryKey: ['farmers', page], queryFn: () => fetchFarmers(page) });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => { const { error } = await supabase.rpc('admin_delete_user', { target: id }); if (error) throw error; },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['farmers'] }); setDeleteTarget(null); toast.success('Farmer and their data deleted'); },
    onError: (e: Error) => toast.error(e.message),
  });

  const upsertMutation = useMutation({
    mutationFn: async (updates: Partial<Profile>) => {
      const { data, error } = await supabase.from('profiles').update(updates).eq('id', updates.id).select('id');
      if (error) throw error;
      if (!data?.length) throw new Error('Not saved: you do not have permission to edit this user.');
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['farmers'] }); setEditTarget(null); toast.success('Updated'); },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <AppLayout title="Farmers" subtitle="Manage farmers">
      <DataTable loading={isLoading} empty={!isLoading && data?.data.length === 0}>
        <thead><tr><Th>Farmer</Th><Th>Contact</Th><Th>Farm</Th><Th>District</Th><Th>Actions</Th></tr></thead>
        <tbody>
          {data?.data.map((f) => (
            <tr key={f.id}>
              <Td><span className="font-semibold text-gray-900">{f.full_name || 'Unnamed'}</span></Td>
              <Td>
                <div className="flex flex-col">
                  <span className="text-gray-900">{f.email || 'No email provided'}</span>
                  {f.phone && <span className="text-gray-500 text-[12px]">{f.phone}</span>}
                </div>
              </Td>
              <Td><span className="text-gray-500">{f.farm_name || 'N/A'}</span></Td>
              <Td><span className="text-gray-500">{f.district || 'Not assigned'}</span></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => setEditTarget(f)} className="p-2 rounded hover:bg-gray-100"><Search size={16}/></button>
                  <button onClick={() => setDeleteTarget(f)} className="p-2 rounded hover:bg-red-50"><Trash2 size={16} color="#D94E4E"/></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>
      {(data?.count ?? 0) > PAGE_SIZE && <Pagination page={page} pageSize={PAGE_SIZE} total={data?.count ?? 0} onPageChange={setPage} />}
      
      <Modal open={!!editTarget} onClose={() => setEditTarget(null)} title="Edit Farmer">
        {editTarget && (
          <div className="space-y-4">
            <div><label className="lumina-label">Full Name</label><input className="lumina-input" defaultValue={editTarget.full_name} onChange={(e) => editTarget.full_name = e.target.value} /></div>
            <div><label className="lumina-label">Email</label><input className="lumina-input" defaultValue={editTarget.email || ''} onChange={(e) => editTarget.email = e.target.value} /></div>
            <div><label className="lumina-label">Mobile Number</label><input className="lumina-input" defaultValue={editTarget.phone || ''} onChange={(e) => editTarget.phone = e.target.value} /></div>
            <div><label className="lumina-label">Farm Name</label><input className="lumina-input" defaultValue={editTarget.farm_name ?? ''} onChange={(e) => editTarget.farm_name = e.target.value} /></div>
            <div><label className="lumina-label">District</label><input className="lumina-input" defaultValue={editTarget.district ?? ''} onChange={(e) => editTarget.district = e.target.value} /></div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <button className="btn-secondary" onClick={() => setEditTarget(null)}>Cancel</button>
              <button className="btn-primary" onClick={() => upsertMutation.mutate(editTarget)} disabled={upsertMutation.isPending}>Save</button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Delete farmer?" message={`Delete ${deleteTarget?.full_name ?? 'this farmer'} and all their scans and farm records? This cannot be undone.`} loading={deleteMutation.isPending} />
    </AppLayout>
  );
}
