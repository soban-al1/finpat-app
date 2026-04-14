import React, { useState } from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { formatCurrency, convertCurrency } from '../lib/utils';
import { ShieldCheck, AlertCircle, Info } from 'lucide-react';

export const MonthlyPlan: React.FC = () => {
  const { userData } = useFinData();
  const [remittanceBuffer, setRemittanceBuffer] = useState(0);

  const totalIncome = userData.income.amount;
  const totalObligations = userData.obligations.reduce((acc, o) => {
    return acc + convertCurrency(o.amount, o.currency, userData.income.currency);
  }, 0);
  const remaining = totalIncome - totalObligations - remittanceBuffer;
  
  const isSafe = remaining > (totalIncome * 0.1); // 10% buffer

  return (
    <div className="space-y-8 pb-24">
      <header className="space-y-2">
        <h1 className="text-3xl font-extrabold text-primary tracking-tight">Monthly Plan</h1>
        <p className="text-on-surface-variant text-sm font-medium">Optimize your allocations and safety buffer.</p>
      </header>

      {/* Clarity Header - Redesigned for impact */}
      <div className="p-8 bg-primary rounded-[2.5rem] text-white shadow-2xl shadow-primary/30 space-y-8 relative overflow-hidden">
        {/* Decorative background element */}
        <div className="absolute -top-24 -right-24 w-64 h-64 bg-white/10 rounded-full blur-3xl" />
        
        <div className="flex justify-between items-start relative z-10">
          <div className="space-y-1">
            <p className="text-[10px] font-black uppercase tracking-[0.2em] opacity-60">Safe to Spend</p>
            <h2 className="text-5xl font-black tracking-tighter">
              {formatCurrency(remaining > 0 ? remaining : 0, userData.income.currency)}
            </h2>
          </div>
          <div className="bg-white/15 p-4 rounded-[1.25rem] backdrop-blur-xl border border-white/10 shadow-inner">
            {isSafe ? <ShieldCheck className="w-8 h-8" /> : <AlertCircle className="w-8 h-8 text-error-container" />}
          </div>
        </div>

        <div className="space-y-3 relative z-10">
          <div className="flex justify-between items-end text-[10px] font-black uppercase tracking-widest opacity-60">
            <span>Utilization</span>
            <span>{Math.round((totalObligations / totalIncome) * 100)}%</span>
          </div>
          <div className="h-3 bg-white/20 rounded-full overflow-hidden border border-white/5">
            <motion.div 
              initial={{ width: 0 }}
              animate={{ width: `${Math.min(100, (totalObligations / totalIncome) * 100)}%` }}
              className="h-full bg-white relative"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/30 to-white/0" />
            </motion.div>
          </div>
        </div>

        <div className="flex justify-between items-center relative z-10 pt-2 border-t border-white/10">
          <div className="space-y-0.5">
            <p className="text-[9px] font-black uppercase tracking-widest opacity-50">Committed</p>
            <p className="text-sm font-extrabold">{formatCurrency(totalObligations, userData.income.currency)}</p>
          </div>
          <div className="text-right space-y-0.5">
            <p className="text-[9px] font-black uppercase tracking-widest opacity-50">Total Income</p>
            <p className="text-sm font-extrabold">{formatCurrency(totalIncome, userData.income.currency)}</p>
          </div>
        </div>
      </div>

      {/* Adjustment Sliders - Premium feel */}
      <section className="bg-surface-container-lowest rounded-[2.5rem] p-6 shadow-sm border border-surface-container/50 space-y-8">
        <div className="space-y-6">
          <div className="flex justify-between items-end">
            <div className="space-y-1">
              <h3 className="text-lg font-black text-primary tracking-tight">Extra Spending</h3>
              <p className="text-[10px] font-bold text-on-surface-variant/40 uppercase tracking-widest">Adjust your buffer</p>
            </div>
            <div className="text-right">
              <span className="text-2xl font-black text-primary tracking-tighter">{formatCurrency(remittanceBuffer, userData.income.currency)}</span>
            </div>
          </div>
          
          <div className="relative pt-2">
            <input 
              type="range"
              min="0"
              max={totalIncome - totalObligations}
              step="50"
              value={remittanceBuffer}
              onChange={(e) => setRemittanceBuffer(Number(e.target.value))}
              className="w-full h-3 bg-surface-container rounded-full appearance-none cursor-pointer accent-primary"
            />
            <div className="flex justify-between text-[9px] font-black text-on-surface-variant/30 uppercase tracking-widest mt-4">
              <span>Minimum</span>
              <span>Max Available</span>
            </div>
          </div>
        </div>

        <div className="p-5 bg-primary/5 rounded-[1.5rem] border border-primary/10 flex gap-4 items-start">
          <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary shrink-0">
            <Info className="w-5 h-5" />
          </div>
          <p className="text-xs text-on-surface-variant/80 leading-relaxed font-medium">
            Increasing your spending reduces your monthly buffer. We recommend keeping at least <span className="text-primary font-bold">10%</span> of your income for unexpected expenses.
          </p>
        </div>
      </section>

      {/* Breakdown - Uniform with other pages */}
      <section className="space-y-4">
        <div className="flex items-center gap-3 px-2">
          <h3 className="text-lg font-black text-primary tracking-tight">Commitment Breakdown</h3>
          <div className="h-px flex-grow bg-surface-container/50" />
        </div>
        
        <div className="space-y-4">
          {userData.obligations.map((obj) => (
            <div key={obj.id} className="p-5 bg-surface-container-lowest rounded-[2rem] shadow-sm border border-surface-container/50 flex justify-between items-center group hover:bg-surface-container-low/30 transition-all">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-primary/5 rounded-2xl flex items-center justify-center text-primary border border-primary/10 group-hover:scale-110 transition-transform">
                  <ShieldCheck className="w-6 h-6" />
                </div>
                <div className="space-y-0.5">
                  <p className="font-extrabold text-on-surface tracking-tight">{obj.title}</p>
                  <p className="text-[9px] font-black uppercase tracking-widest text-on-surface-variant/40">Essential Commitment</p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-black text-primary text-lg tracking-tighter leading-none">{formatCurrency(obj.amount, obj.currency)}</p>
              </div>
            </div>
          ))}
          {userData.obligations.length === 0 && (
            <div className="py-12 text-center space-y-3 bg-surface-container-low/20 rounded-[2rem] border border-dashed border-surface-container">
              <p className="text-xs font-bold text-on-surface-variant/40 uppercase tracking-widest italic">No obligations added yet.</p>
            </div>
          )}
        </div>
      </section>
    </div>
  );
};
