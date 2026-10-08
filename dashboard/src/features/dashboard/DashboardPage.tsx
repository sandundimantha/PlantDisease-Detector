import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Users, Briefcase, ShieldAlert, ScanLine, CheckCircle2, MessageSquare } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { supabase } from '../../lib/supabase';
import { AppLayout } from '../../components/layout/AppLayout';
import { StatCard } from '../../components/ui/StatCard';
import { DataTable, Th, Td } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { timeAgo } from '../../lib/utils';
import type { Consultation } from '../../types/database';

const DAYS = 14;

/** Row count for a table with optional filters; 0 when it cannot be read. */
async function countRows(table: string, filter?: (q: any) => any) {
  let query = supabase.from(table).select('id', { count: 'exact', head: true });
  if (filter) query = filter(query);
  const { count, error } = await query;
  return error ? 0 : count ?? 0;
}

async function fetchStats() {
  const [farmers, officers, pending, open, resolved, scans, feedback] = await Promise.all([
    countRows('profiles', (q) => q.eq('role', 'farmer')),
    countRows('profiles', (q) => q.eq('role', 'officer')),
    countRows('consultations', (q) => q.eq('status', 'pending')),
    countRows('consultations', (q) => q.eq('status', 'open')),
    countRows('consultations', (q) => q.eq('status', 'resolved')),
    countRows('scans'),
    countRows('feedback'),
  ]);
  return { farmers, officers, pending, open, resolved, scans, feedback };
}

/** Scans per day for the last two weeks. */
async function fetchScanTrend() {
  const since = new Date();
  since.setHours(0, 0, 0, 0);
  since.setDate(since.getDate() - (DAYS - 1));
  const { data } = await supabase.from('scans').select('scanned_at').gte('scanned_at', since.toISOString()).limit(5000);
  const buckets = new Map<string, number>();
  for (let i = 0; i < DAYS; i++) {
    const d = new Date(since);
    d.setDate(since.getDate() + i);
    buckets.set(d.toISOString().slice(0, 10), 0);
  }
  for (const row of data ?? []) {
    const key = new Date(row.scanned_at as string).toISOString().slice(0, 10);
    if (buckets.has(key)) buckets.set(key, (buckets.get(key) ?? 0) + 1);
  }
  return [...buckets.entries()].map(([day, scans]) => ({
    day: new Date(day).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }),
    scans,
  }));
}

type RecentCase = Consultation & { farmer?: { full_name: string } | null };

async function fetchRecentCases() {
  const { data, error } = await supabase
    .from('consultations')
    .select('*, farmer:farmer_id(full_name)')
    .order('created_at', { ascending: false })
    .limit(6);
  if (error) throw error;
  return (data ?? []) as RecentCase[];
}

export function DashboardPage() {
  const navigate = useNavigate();
  const { data: stats } = useQuery({ queryKey: ['dashboard-stats'], queryFn: fetchStats });
  const { data: trend } = useQuery({ queryKey: ['dashboard-scan-trend'], queryFn: fetchScanTrend });
  const { data: recent, isLoading: recentLoading } = useQuery({ queryKey: ['dashboard-recent-cases'], queryFn: fetchRecentCases });

  const v = (n?: number) => (n === undefined ? '…' : n.toLocaleString());

  return (
    <AppLayout title="Dashboard" subtitle="Live overview of farmers, officers, scans and cases">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5 mb-6">
        <StatCard label="Registered Farmers" value={v(stats?.farmers)} icon={Users} color="#1E7045" onClick={() => navigate('/farmers')} />
        <StatCard label="Agriculture Officers" value={v(stats?.officers)} icon={Briefcase} color="#2563EB" onClick={() => navigate('/officers')} />
        <StatCard label="Leaf Scans Uploaded" value={v(stats?.scans)} icon={ScanLine} color="#C87D55" />
        <StatCard label="Cases Waiting for an Officer" value={v(stats?.pending)} icon={ShieldAlert} color="#D97706" onClick={() => navigate('/cases')} />
        <StatCard label="Cases Resolved" value={v(stats?.resolved)} icon={CheckCircle2} color="#059669" onClick={() => navigate('/cases')} />
        <StatCard label="Feedback Received" value={v(stats?.feedback)} icon={MessageSquare} color="#7C3AED" onClick={() => navigate('/feedback')} />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-5 gap-5">
        <div className="lumina-card p-5 xl:col-span-3">
          <h3 className="text-[15px] font-bold mb-1" style={{ color: 'var(--color-text-primary)' }}>Scans in the last {DAYS} days</h3>
          <p className="text-[12px] mb-4" style={{ color: 'var(--color-text-muted)' }}>Scans synced from the mobile app, by day</p>
          <div style={{ width: '100%', height: 260 }}>
            <ResponsiveContainer>
              <BarChart data={trend ?? []} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                <XAxis dataKey="day" tick={{ fontSize: 11 }} interval={1} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                <Tooltip cursor={{ fill: 'rgba(30,112,69,0.06)' }} />
                <Bar dataKey="scans" name="Scans" fill="#1E7045" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="lumina-card p-5 xl:col-span-2">
          <h3 className="text-[15px] font-bold mb-4" style={{ color: 'var(--color-text-primary)' }}>Case status</h3>
          {[
            { label: 'Waiting (pending)', value: stats?.pending, color: '#D97706' },
            { label: 'With an officer (open)', value: stats?.open, color: '#2563EB' },
            { label: 'Resolved', value: stats?.resolved, color: '#059669' },
          ].map((row) => {
            const total = (stats?.pending ?? 0) + (stats?.open ?? 0) + (stats?.resolved ?? 0);
            const pct = total ? Math.round(((row.value ?? 0) / total) * 100) : 0;
            return (
              <div key={row.label} className="mb-4">
                <div className="flex justify-between text-[12px] font-semibold mb-1.5">
                  <span style={{ color: 'var(--color-text-secondary)' }}>{row.label}</span>
                  <span style={{ color: 'var(--color-text-primary)' }}>{v(row.value)} · {pct}%</span>
                </div>
                <div className="h-2 rounded-full bg-gray-100 overflow-hidden">
                  <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, background: row.color }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="mt-6">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-[15px] font-bold" style={{ color: 'var(--color-text-primary)' }}>Latest cases</h3>
          <button className="btn-secondary" onClick={() => navigate('/cases')}>View all</button>
        </div>
        <DataTable loading={recentLoading} empty={!recentLoading && (recent?.length ?? 0) === 0} emptyText="No cases yet.">
          <thead>
            <tr><Th>Farmer</Th><Th>Disease</Th><Th>Severity</Th><Th>Status</Th><Th>Received</Th></tr>
          </thead>
          <tbody>
            {recent?.map((c) => (
              <tr key={c.id}>
                <Td><span className="font-semibold text-[13px]">{c.farmer?.full_name ?? 'Farmer'}</span></Td>
                <Td><span className="text-[13px]">{c.disease_name ?? '—'}</span></Td>
                <Td><span className="text-[12px] capitalize">{c.severity ?? '—'}</span></Td>
                <Td><Badge status={c.status} dot /></Td>
                <Td><span className="text-[12px]">{timeAgo(c.created_at)}</span></Td>
              </tr>
            ))}
          </tbody>
        </DataTable>
      </div>
    </AppLayout>
  );
}
