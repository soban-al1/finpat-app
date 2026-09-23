import React from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { formatCurrency, cn } from '../lib/utils';
import { Wallet, TrendingUp, History, ArrowDownRight, ArrowUpRight } from 'lucide-react';
import { format } from 'date-fns';

export const Savings: React.FC = () => {
  const { userData } = useFinData();

  const totalSavings = userData.savings.reduce((acc, log) => acc + log.amount, 0);
  const salaryCurrency = userData.income.currency;

  const sortedLogs = [...userData.savings].sort((a, b) => 
    new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  return (
    <div className="space-y-8 pb-32">
      <header className="space-y-1">
        <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-[0.2em]">Financial Safety Net</p>
        <h1 className="text-4xl font-extrabold text-primary tracking-tight">Savings</h1>
      </header>

      {/* Total Savings Card */}
      <section className="bg-tertiary rounded-[2.5rem] p-8 text-white shadow-2xl shadow-tertiary/20 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -mr-20 -mt-20 blur-3xl" />
        <div className="relative space-y-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center">
              <Wallet className="w-6 h-6" />
            </div>
            <p className="text-sm font-bold text-white/60 uppercase tracking-widest">Total Saved</p>
          </div>
          <h2 className="text-5xl font-extrabold tracking-tighter">
            {formatCurrency(totalSavings, salaryCurrency)}
          </h2>
          <div className="flex items-center gap-2 text-white/80">
            <TrendingUp className="w-4 h-4" />
            <span className="text-xs font-bold">Growing steadily each cycle</span>
          </div>
        </div>
      </section>

      {/* Savings History */}
      <section className="space-y-4">
        <div className="flex items-center gap-2">
          <History className="w-5 h-5 text-primary" />
          <h2 className="text-xl font-bold text-primary">History</h2>
        </div>

        <div className="space-y-3">
          {sortedLogs.length === 0 ? (
            <div className="p-8 text-center bg-surface-container-low rounded-3xl border border-dashed border-surface-container">
              <p className="text-on-surface-variant text-sm italic">No savings logged yet. Surplus from your cycles will appear here.</p>
            </div>
          ) : (
            sortedLogs.map((log) => (
              <motion.div 
                key={log.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="p-5 bg-surface-container-lowest rounded-3xl border border-surface-container shadow-sm flex items-center justify-between"
              >
                <div className="flex items-center gap-4">
                  <div className={cn(
                    "w-10 h-10 rounded-full flex items-center justify-center",
                    log.type === 'surplus' ? "bg-primary/10 text-primary" : "bg-surface-container text-on-surface-variant"
                  )}>
                    {log.type === 'surplus' ? <ArrowUpRight className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
                  </div>
                  <div>
                    <h3 className="font-bold text-sm">
                      {log.type === 'surplus' ? 'Cycle Surplus' : 'Manual Addition'}
                    </h3>
                    <p className="text-[10px] font-bold text-on-surface-variant/60 uppercase tracking-wider">
                      {format(new Date(log.date), 'MMM d, yyyy')} {log.note ? `• ${log.note}` : ''}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className={cn(
                    "font-bold text-sm",
                    log.type === 'surplus' ? "text-primary" : "text-tertiary"
                  )}>
                    +{formatCurrency(log.amount, log.currency)}
                  </p>
                </div>
              </motion.div>
            ))
          )}
        </div>
      </section>
    </div>
  );
};

const Plus = ({ className }: { className?: string }) => (
  <svg 
    xmlns="http://www.w3.org/2000/svg" 
    width="24" 
    height="24" 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    className={className}
  >
    <path d="M5 12h14"/><path d="M12 5v14"/>
  </svg>
);
