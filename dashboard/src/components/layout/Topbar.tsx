import { Search, Bell } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { getInitials } from '../../lib/utils';

interface TopbarProps {
  title: string;
  subtitle?: string;
}

export function Topbar({ title, subtitle }: TopbarProps) {
  const { user } = useAuth();

  return (
    <div className="h-[72px] px-8 flex items-center justify-between sticky top-0 z-10 backdrop-blur-md" style={{ background: 'rgba(248, 250, 252, 0.8)', borderBottom: '1px solid var(--color-card-border)' }}>
      {/* Title Area */}
      <div>
        <h2 className="text-[20px] font-black tracking-tight" style={{ color: 'var(--color-text-primary)' }}>{title}</h2>
        {subtitle && <p className="text-[12px] font-medium" style={{ color: 'var(--color-text-muted)' }}>{subtitle}</p>}
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-6">
        {/* Global Search */}
        <div className="relative hidden md:block w-64">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input 
            type="text" 
            placeholder="Search platform..." 
            className="w-full pl-9 pr-4 py-2 rounded-xl text-[13px] bg-white border outline-none focus:ring-2 transition-shadow"
            style={{ borderColor: 'var(--color-card-border)' }}
          />
        </div>

        {/* Action Icons */}
        <div className="flex items-center gap-3">
          <button className="relative w-9 h-9 rounded-xl flex items-center justify-center bg-white border hover:bg-gray-50 transition-colors" style={{ borderColor: 'var(--color-card-border)' }}>
            <Bell size={16} style={{ color: 'var(--color-text-secondary)' }} />
            <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-red-500 border border-white" />
          </button>
        </div>

        {/* Admin Profile */}
        <div className="flex items-center gap-3 pl-6 border-l" style={{ borderColor: 'var(--color-card-border)' }}>
          <div className="text-right">
            <p className="text-[13px] font-bold" style={{ color: 'var(--color-text-primary)' }}>{user?.full_name || 'Admin'}</p>
            <p className="text-[11px] font-medium" style={{ color: 'var(--color-text-muted)' }}>System Administrator</p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#0B3C2D] to-[#125843] flex items-center justify-center text-white font-bold shadow-md">
            {getInitials(user?.full_name || 'Admin')}
          </div>
        </div>
      </div>
    </div>
  );
}
