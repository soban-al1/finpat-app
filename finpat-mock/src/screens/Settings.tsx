import React from 'react';
import { useFinData } from '../context/FinContext';
import { User, Globe, Bell, LogOut, Trash2 } from 'lucide-react';

export const Settings: React.FC = () => {
  const { userData, resetData, logout } = useFinData();

  return (
    <div className="space-y-10 pb-32">
      <header className="space-y-2">
        <h1 className="text-3xl font-black text-primary tracking-tight">Settings</h1>
        <p className="text-on-surface-variant text-sm font-medium">Manage your profile and app preferences.</p>
      </header>

      <div className="space-y-8">
        <section className="space-y-4">
          <h3 className="text-[10px] font-black uppercase tracking-[0.2em] text-on-surface-variant/40 px-2">Profile & Account</h3>
          <div className="bg-surface-container-lowest rounded-[2.5rem] overflow-hidden border border-surface-container/50 shadow-sm">
            <div className="p-6 flex items-center gap-5 hover:bg-surface-container-low/30 transition-all cursor-pointer group">
              <div className="w-14 h-14 bg-primary/5 rounded-[1.25rem] flex items-center justify-center text-primary border border-primary/10 group-hover:scale-110 transition-transform">
                <User className="w-7 h-7" />
              </div>
              <div className="flex-1 space-y-0.5">
                <p className="font-extrabold text-base text-on-surface tracking-tight">Personal Info</p>
                <p className="text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">Working in {userData.workLocation}</p>
              </div>
            </div>
            <div className="p-6 flex items-center gap-5 hover:bg-surface-container-low/30 transition-all cursor-pointer group border-t border-surface-container/50">
              <div className="w-14 h-14 bg-primary/5 rounded-[1.25rem] flex items-center justify-center text-primary border border-primary/10 group-hover:scale-110 transition-transform">
                <Globe className="w-7 h-7" />
              </div>
              <div className="flex-1 space-y-0.5">
                <p className="font-extrabold text-base text-on-surface tracking-tight">Salary Currency</p>
                <p className="text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">{userData.income.currency}</p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-4">
          <h3 className="text-[10px] font-black uppercase tracking-[0.2em] text-on-surface-variant/40 px-2">Preferences</h3>
          <div className="bg-surface-container-lowest rounded-[2.5rem] overflow-hidden border border-surface-container/50 shadow-sm">
            <div className="p-6 flex items-center gap-5 hover:bg-surface-container-low/30 transition-all cursor-pointer group">
              <div className="w-14 h-14 bg-primary/5 rounded-[1.25rem] flex items-center justify-center text-primary border border-primary/10 group-hover:scale-110 transition-transform">
                <Bell className="w-7 h-7" />
              </div>
              <div className="flex-1 space-y-0.5">
                <p className="font-extrabold text-base text-on-surface tracking-tight">Notifications</p>
                <p className="text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">Spending reminders</p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-4 pt-6">
          <button 
            onClick={logout}
            className="w-full py-5 bg-surface-container text-on-surface rounded-full font-black text-sm flex items-center justify-center gap-3 hover:bg-surface-container-high transition-all shadow-sm"
          >
            <LogOut className="w-5 h-5" />
            Sign Out
          </button>
          <button 
            onClick={resetData}
            className="w-full py-5 bg-error/5 text-error rounded-full font-black text-sm flex items-center justify-center gap-3 hover:bg-error/10 transition-all border border-error/10"
          >
            <Trash2 className="w-5 h-5" />
            Reset All Data
          </button>
        </section>
      </div>
    </div>
  );
};
