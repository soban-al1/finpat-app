import React, { useState } from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { Currency, Remittance, CURRENCY_FLAGS } from '../types';
import { Plus, X, ArrowUpRight, History } from 'lucide-react';
import { formatCurrency } from '../lib/utils';

export const RemittanceLog: React.FC = () => {
  const { userData, addRemittance } = useFinData();
  const [showAdd, setShowAdd] = useState(false);
  const [newRem, setNewRem] = useState({
    amount: 0,
    currency: userData.income.currency,
    targetCurrency: 'INR' as Currency,
    rate: 1,
    purpose: '',
    centerId: userData.centers[0]?.id || 'miscellaneous',
  });

  const handleAdd = () => {
    if (!newRem.amount || !newRem.purpose) return;
    const now = new Date();
    addRemittance({
      id: Math.random().toString(36).substr(2, 9),
      date: now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
      time: now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
      amount: newRem.amount,
      currency: newRem.currency as Currency,
      targetCurrency: newRem.targetCurrency as Currency,
      rate: newRem.rate,
      purpose: newRem.purpose,
      centerId: newRem.centerId,
    });
    setShowAdd(false);
    setNewRem({ ...newRem, amount: 0, purpose: '' });
  };

  return (
    <div className="space-y-8 pb-24">
      <header className="space-y-2">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-extrabold text-primary tracking-tight">Spent</h1>
          <button 
            onClick={() => setShowAdd(true)}
            className="w-12 h-12 bg-primary text-white rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-105 transition-transform"
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
        <p className="text-on-surface-variant text-sm font-medium">Track your daily expenses and commitment payments.</p>
      </header>

      <div className="space-y-4">
        {userData.remittances.length > 0 ? (
          [...userData.remittances].reverse().map((rem) => (
            <div key={rem.id} className="p-5 bg-surface-container-lowest rounded-[2rem] shadow-sm border border-surface-container/50 flex items-center justify-between group hover:bg-surface-container-low/30 transition-all">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-primary/5 rounded-2xl flex items-center justify-center text-primary border border-primary/10 group-hover:scale-110 transition-transform">
                  <ArrowUpRight className="w-6 h-6" />
                </div>
                <div className="space-y-0.5">
                  <h3 className="font-extrabold text-on-surface tracking-tight">{rem.purpose}</h3>
                  <div className="flex items-center gap-2">
                    <p className="text-[9px] text-on-surface-variant/40 font-black uppercase tracking-widest">
                      {rem.date} • {rem.time}
                    </p>
                    {rem.obligationId && (
                      <span className="text-[8px] font-black uppercase tracking-widest bg-tertiary/10 text-tertiary px-1.5 py-0.5 rounded-full">Commitment</span>
                    )}
                  </div>
                </div>
              </div>
              <div className="text-right">
                <p className="font-black text-primary text-lg tracking-tighter leading-none">{formatCurrency(rem.amount, rem.currency)}</p>
                {rem.rate > 1 && (
                  <p className="text-[9px] text-on-surface-variant/40 font-bold uppercase tracking-widest mt-1">
                    Rate: {rem.rate}
                  </p>
                )}
              </div>
            </div>
          ))
        ) : (
          <div className="p-12 text-center space-y-4">
            <History className="w-12 h-12 text-on-surface-variant/20 mx-auto" />
            <p className="text-on-surface-variant font-medium">No spending logged yet.</p>
          </div>
        )}
      </div>

      {showAdd && (
        <div className="fixed inset-0 bg-on-surface/40 backdrop-blur-md z-50 flex items-end sm:items-center justify-center p-4">
          <motion.div 
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="bg-surface w-full max-w-md rounded-[2.5rem] p-8 space-y-8 shadow-2xl border border-surface-container"
          >
            <div className="flex justify-between items-center">
              <div className="space-y-1.5">
                <h2 className="text-3xl font-black text-primary tracking-tight leading-none">Log Spending</h2>
                <p className="text-[10px] font-bold text-on-surface-variant/40 uppercase tracking-widest">Record a new transaction</p>
              </div>
              <button 
                onClick={() => setShowAdd(false)}
                className="w-10 h-10 bg-surface-container rounded-xl flex items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-all"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="space-y-6">
              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1">Purpose</label>
                <input 
                  type="text"
                  className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium"
                  placeholder="e.g. Family Support, Rent"
                  value={newRem.purpose}
                  onChange={(e) => setNewRem({ ...newRem, purpose: e.target.value })}
                />
              </div>
              <div className="flex gap-4 items-end">
                <div className="flex-1 space-y-2">
                  <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Amount</label>
                  <input 
                    type="number"
                    className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-black text-xl"
                    value={newRem.amount || ''}
                    onChange={(e) => setNewRem({ ...newRem, amount: Number(e.target.value) })}
                  />
                </div>
                <div className="w-36 space-y-2">
                  <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Currency</label>
                  <div className="relative">
                    <select 
                      className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-black appearance-none"
                      value={newRem.currency}
                      onChange={(e) => setNewRem({ ...newRem, currency: e.target.value as Currency })}
                    >
                      {Object.keys(CURRENCY_FLAGS).map(c => (
                        <option key={c} value={c}>{CURRENCY_FLAGS[c as Currency]} {c}</option>
                      ))}
                    </select>
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant/40">
                      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                    </div>
                  </div>
                </div>
              </div>
              <div className="flex gap-4 items-end">
                <div className="flex-1 space-y-2">
                  <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Target Currency</label>
                  <div className="relative">
                    <select 
                      className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-black appearance-none"
                      value={newRem.targetCurrency}
                      onChange={(e) => setNewRem({ ...newRem, targetCurrency: e.target.value as Currency })}
                    >
                      {Object.keys(CURRENCY_FLAGS).map(c => (
                        <option key={c} value={c}>{CURRENCY_FLAGS[c as Currency]} {c}</option>
                      ))}
                    </select>
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant/40">
                      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                    </div>
                  </div>
                </div>
                <div className="w-28 space-y-2">
                  <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Rate</label>
                  <input 
                    type="number"
                    step="0.01"
                    className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-black text-xl"
                    value={newRem.rate || ''}
                    onChange={(e) => setNewRem({ ...newRem, rate: Number(e.target.value) })}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1">Category / Center</label>
                <div className="relative">
                  <select 
                    className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-black appearance-none"
                    value={newRem.centerId}
                    onChange={(e) => setNewRem({ ...newRem, centerId: e.target.value })}
                  >
                    <optgroup label="Commitment Centers">
                      {userData.centers.map(c => (
                        <option key={c.id} value={c.id}>{c.name}</option>
                      ))}
                    </optgroup>
                    <optgroup label="Additional Categories">
                      <option value="entertainment">Entertainment</option>
                      <option value="miscellaneous">Miscellaneous</option>
                      <option value="personal">Personal</option>
                    </optgroup>
                  </select>
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant/40">
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                  </div>
                </div>
              </div>
            </div>

            <button 
              onClick={handleAdd}
              className="w-full py-5 bg-primary text-white rounded-full font-black text-lg shadow-xl shadow-primary/20 hover:shadow-2xl transition-all"
            >
              Log Spending
            </button>
          </motion.div>
        </div>
      )}
    </div>
  );
};
