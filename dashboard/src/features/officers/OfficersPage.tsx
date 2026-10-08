import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Edit2, XCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { DataTable, Th, Td } from '../../components/ui/DataTable';
import { Modal, ConfirmModal } from '../../components/ui/Modal';
import { RoleBadge } from '../../components/ui/Badge';
import toast from 'react-hot-toast';
import type { Profile } from '../../types/database';

const PAGE_SIZE = 10;
const SRI_LANKA_DISTRICTS = ['Colombo','Gampaha','Kalutara','Kandy','Matale','Nuwara Eliya','Galle','Matara','Hambantota','Jaffna','Kilinochchi','Mannar','Mullaitivu','Vavuniya','Puttalam','Kurunegala','Anuradhapura','Polonnaruwa','Badulla','Moneragala','Ratnapura','Kegalle','Trincomalee','Batticaloa','Ampara'];

async function fetchOfficers(page: number, search: string) {
  let query = supabase.from('profiles').select('*', { count: 'exact' }).eq('role', 'officer').order('created_at', { ascending: false }).range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
  if (search) query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,district.ilike.%${search}%`);
  const { data, count, error } = await query;
  if (error) throw error;
  return { data: (data ?? []) as Profile[], count: count ?? 0 };
}

const EMPTY_FORM = { full_name: '', email: '', phone: '', district: '', bio: '' };

export function OfficersPage() {
  const queryClient = useQueryClient();
  const [page] = useState(1);
  const [search] = useState('');
  const [editTarget, setEditTarget] = useState<Profile | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Profile | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [creating, setCreating] = useState(false);

  const { data, isLoading } = useQuery({ queryKey: ['officers', page, search], queryFn: () => fetchOfficers(page, search) });

  const updateMutation = useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Profile> }) => {
      const { error } = await supabase.from('profiles').update(updates).eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['officers'] }); toast.success('Officer updated!'); setEditTarget(null); },
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('profiles').update({ role: 'farmer' }).eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['officers'] }); toast.success('Removed'); setDeleteTarget(null); },
  });

  async function handleCreate() {
    if (!form.email || !form.full_name) return toast.error('Required fields missing');
    setCreating(true);
    try {
      // Create a secondary client that doesn't persist the session, so we don't log out the admin
      const { createClient } = await import('@supabase/supabase-js');
      const tempClient = createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, { auth: { persistSession: false } });
      
      const { data: authData, error: authError } = await tempClient.auth.signUp({ 
        email: form.email, 
        password: 'Password123!', 
        options: { data: { full_name: form.full_name, role: 'officer' } } 
      });
      if (authError) throw authError;

      // The trigger creates the profile. We just need to update it with the additional details.
      if (authData?.user) {
        await supabase.from('profiles').update({ 
          role: 'officer', 
          full_name: form.full_name, 
          phone: form.phone, 
          district: form.district, 
          bio: form.bio, 
          email: form.email 
        }).eq('id', authData.user.id);
      }
      queryClient.invalidateQueries({ queryKey: ['officers'] });
      toast.success('Officer created successfully!'); 
      setCreateOpen(false); 
      setForm(EMPTY_FORM);
    } catch (e: any) { 
      toast.error(e.message); 
    } finally { 
      setCreating(false); 
    }
  }

  function set(key: keyof typeof EMPTY_FORM, val: string) { setForm((f) => ({ ...f, [key]: val })); }

  return (
    <AppLayout title="Ag-Officers" subtitle="Manage agricultural officers">
      <div className="flex items-center gap-3 mb-5"><button className="btn-primary" onClick={() => setCreateOpen(true)}><Plus size={15}/> Add</button></div>
      <DataTable loading={isLoading} empty={!isLoading && data?.data.length === 0}>
        <thead><tr><Th>Officer</Th><Th>Contact</Th><Th>District</Th><Th>Role</Th><Th>Actions</Th></tr></thead>
        <tbody>
          {data?.data.map((o) => (
            <tr key={o.id}>
              <Td><span className="font-semibold text-gray-900">{o.full_name || 'Unnamed'}</span></Td>
              <Td>
                <div className="flex flex-col">
                  <span className="text-gray-900">{o.email || 'No email provided'}</span>
                  {o.phone && <span className="text-gray-500 text-[12px]">{o.phone}</span>}
                </div>
              </Td>
              <Td><span className="text-gray-500">{o.district || 'Not assigned'}</span></Td>
              <Td><RoleBadge role={o.role} /></Td>
              <Td>
                <div className="flex items-center gap-2">
                  <button onClick={() => setEditTarget(o)} className="p-2 rounded hover:bg-gray-100"><Edit2 size={16}/></button>
                  <button onClick={() => setDeleteTarget(o)} className="p-2 rounded hover:bg-red-50"><XCircle size={16} color="#D94E4E"/></button>
                </div>
              </Td>
            </tr>
          ))}
        </tbody>
      </DataTable>
      
      <Modal open={!!editTarget} onClose={() => setEditTarget(null)} title="Edit Officer">
        {editTarget && (
          <div className="space-y-4">
            <div>
              <label className="lumina-label">Full Name</label>
              <input className="lumina-input" defaultValue={editTarget.full_name || ''} onChange={(e) => setEditTarget({...editTarget, full_name: e.target.value})} />
            </div>
            <div>
              <label className="lumina-label">Email Address</label>
              <input type="email" className="lumina-input" defaultValue={editTarget.email || ''} onChange={(e) => setEditTarget({...editTarget, email: e.target.value})} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="lumina-label">Mobile Number</label>
                <input className="lumina-input" defaultValue={editTarget.phone || ''} onChange={(e) => setEditTarget({...editTarget, phone: e.target.value})} placeholder="+947XXXXXXXX" />
              </div>
              <div>
                <label className="lumina-label">District</label>
                <select className="lumina-input" defaultValue={editTarget.district || ''} onChange={(e) => setEditTarget({...editTarget, district: e.target.value})}>
                  <option value="">Unassigned</option>{SRI_LANKA_DISTRICTS.map(d => <option key={d}>{d}</option>)}
                </select>
              </div>
            </div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <button className="btn-secondary" onClick={() => setEditTarget(null)}>Cancel</button>
              <button className="btn-primary" onClick={() => updateMutation.mutate({ 
                id: editTarget.id, 
                updates: { 
                  full_name: editTarget.full_name,
                  email: editTarget.email,
                  district: editTarget.district, 
                  phone: editTarget.phone 
                } 
              })}>Save</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal open={createOpen} onClose={() => setCreateOpen(false)} title="Add New Officer">
        <div className="space-y-4">
          <div><label className="lumina-label">Full Name</label><input className="lumina-input" value={form.full_name} onChange={e => set('full_name', e.target.value)} /></div>
          <div><label className="lumina-label">Email Address</label><input type="email" className="lumina-input" value={form.email} onChange={e => set('email', e.target.value)} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><label className="lumina-label">Mobile Number</label><input className="lumina-input" value={form.phone} onChange={e => set('phone', e.target.value)} placeholder="+947XXXXXXXX" /></div>
            <div>
              <label className="lumina-label">District</label>
              <select className="lumina-input" value={form.district} onChange={e => set('district', e.target.value)}>
                <option value="">Select...</option>{SRI_LANKA_DISTRICTS.map(d => <option key={d}>{d}</option>)}
              </select>
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t">
            <button className="btn-secondary" onClick={() => setCreateOpen(false)}>Cancel</button>
            <button className="btn-primary" onClick={handleCreate} disabled={creating}>{creating ? 'Saving...' : 'Add Officer'}</button>
          </div>
        </div>
      </Modal>

      <ConfirmModal open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)} title="Remove?" message="Remove officer role?" />
    </AppLayout>
  );
}
