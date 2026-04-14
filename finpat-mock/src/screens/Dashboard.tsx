import React, { useState } from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { formatCurrency, cn, convertCurrency } from '../lib/utils';
import { Calendar, CheckCircle2, AlertCircle, ShieldCheck, ArrowUpRight, Gauge, RefreshCw, Plus, Wallet } from 'lucide-react';
import { format, differenceInDays, endOfMonth, isLastDayOfMonth } from 'date-fns';

export const Dashboard: React.FC = () => {
  const { userData, toggleObligationComplete, resetCycle, addSavings } = useFinData();
  const [showManualSavings, setShowManualSavings] = useState(false);
  const [manualSavingsAmount, setManualSavingsAmount] = useState<number>(0);

  const now = new Date();
  const daysLeft = differenceInDays(endOfMonth(now), now);
  const isEndMonth = daysLeft <= 2; // Show reset option in last 2 days or if user wants

  const totalIncome = userData.income.amount;
  const salaryCurrency = userData.income.currency;

  const totalCommitmentsPaid = userData.obligations
    .filter(o => o.isCompleted)
    .reduce((acc, obj) => {
      return acc + convertCurrency(obj.amount, obj.currency, salaryCurrency);
    }, 0);
  
  const totalOtherSpent = userData.remittances
    .filter(r => !r.obligationId)
    .reduce((acc, r) => {
      return acc + convertCurrency(r.amount, r.currency, salaryCurrency);
    }, 0);

  const totalSpent = totalCommitmentsPaid + totalOtherSpent;

  // Manual savings during the month should be deducted from the available balance
  const totalManualSavingsThisMonth = userData.savings
    .filter(s => s.type === 'manual' && new Date(s.date).getMonth() === now.getMonth())
    .reduce((acc, s) => acc + s.amount, 0);

  const remainingBalance = totalIncome - totalSpent - totalManualSavingsThisMonth;
  const pressurePercent = totalIncome > 0 ? ((totalSpent + totalManualSavingsThisMonth) / totalIncome) * 100 : 0;

  // Find next due obligation
  const nextDue = [...userData.obligations]
    .filter(o => !o.isCompleted && o.dueDate)
    .sort((a, b) => new Date(a.dueDate!).getTime() - new Date(b.dueDate!).getTime())[0];

  // Sort obligations for the list: Pending first, then by amount
  const sortedObligations = [...userData.obligations].sort((a, b) => {
    if (a.isCompleted !== b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    return b.amount - a.amount;
  });

  const handleManualSavings = () => {
    if (manualSavingsAmount <= 0) return;
    addSavings(manualSavingsAmount, 'manual', 'Manual savings from current balance');
    setManualSavingsAmount(0);
    setShowManualSavings(false);
  };

  return (
    <div className="space-y-8 pb-32">
      {/* Header Section */}
      <header className="space-y-1">
        <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-[0.2em]">Current Cycle</p>
        <div className="flex items-center justify-between">
          <h1 className="text-4xl font-extrabold text-primary tracking-tight">
            {format(now, 'MMMM yyyy')}
          </h1>
          <div className="flex items-center gap-2 bg-surface-container-low px-4 py-2 rounded-2xl border border-surface-container">
            <Calendar className="w-4 h-4 text-primary" />
            <span className="text-xs font-bold text-primary">{daysLeft} days left</span>
          </div>
        </div>
      </header>

      {/* Main Financial Card */}
      <section className="relative overflow-hidden bg-[#004d60] rounded-[2.5rem] p-8 text-white shadow-2xl shadow-primary/20">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -mr-20 -mt-20 blur-3xl" />
        
        <div className="relative space-y-8">
          <div className="flex justify-between items-start">
            <div className="space-y-2">
              <p className="text-sm font-bold text-white/60 uppercase tracking-widest">Total Monthly Income</p>
              <h2 className="text-5xl font-extrabold tracking-tighter">
                {formatCurrency(totalIncome, salaryCurrency)}
              </h2>
            </div>
            {isEndMonth && (
              <button 
                onClick={() => {
                  if (window.confirm('Are you sure you want to reset the cycle? Surplus will be moved to savings.')) {
                    resetCycle();
                  }
                }}
                className="p-3 bg-white/10 hover:bg-white/20 rounded-2xl transition-all flex items-center gap-2"
              >
                <RefreshCw className="w-5 h-5" />
                <span className="text-[10px] font-bold uppercase tracking-widest">Reset</span>
              </button>
            )}
          </div>

          <div className="h-px bg-white/10 w-full" />

          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-2">
              <p className="text-[10px] font-bold text-white/40 uppercase tracking-widest">Total Spent</p>
              <p className="text-2xl font-extrabold">{formatCurrency(totalSpent, salaryCurrency)}</p>
            </div>
            <div className="space-y-2">
              <p className="text-[10px] font-bold text-white/40 uppercase tracking-widest">Remaining Balance</p>
              <p className="text-2xl font-extrabold text-[#76f2e1]">{formatCurrency(remainingBalance, salaryCurrency)}</p>
            </div>
          </div>
        </div>
      </section>

      {/* Pressure Indicator Card - Redesigned for elegance */}
      <section className="bg-surface-container-lowest rounded-[2.5rem] p-6 shadow-sm border border-surface-container/50">
        <div className="flex items-center gap-5">
          <div className="flex-shrink-0 w-14 h-14 bg-primary/5 rounded-[1.25rem] flex items-center justify-center text-primary border border-primary/10">
            <Gauge className="w-8 h-8" />
          </div>
          
          <div className="flex-grow space-y-4">
            <div className="flex items-end justify-between">
              <div className="space-y-1">
                <h3 className="text-lg font-extrabold text-primary leading-none tracking-tight">Pressure Indicator</h3>
                <div className="flex items-center gap-2">
                  <div className={cn(
                    "px-2 py-0.5 rounded-full text-[8px] font-black uppercase tracking-[0.15em]",
                    pressurePercent > 80 ? "bg-error/10 text-error" : "bg-tertiary/10 text-tertiary"
                  )}>
                    {pressurePercent > 80 ? 'Critical' : 'Optimal'}
                  </div>
                  <span className="text-[10px] font-bold text-on-surface-variant/40 uppercase tracking-widest">Status</span>
                </div>
              </div>
              <div className="text-right">
                <p className="text-2xl font-black text-primary leading-none tracking-tighter">
                  {Math.round(pressurePercent)}%
                </p>
                <p className="text-[9px] font-bold text-on-surface-variant/50 uppercase tracking-widest mt-1">Capacity Used</p>
              </div>
            </div>

            <div className="relative h-3 bg-surface-container rounded-full overflow-hidden">
              <motion.div 
                initial={{ width: 0 }}
                animate={{ width: `${Math.min(100, pressurePercent)}%` }}
                className={cn(
                  "h-full transition-all relative",
                  pressurePercent > 80 ? "bg-error" : "bg-primary"
                )}
              >
                <div className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/20 to-white/0" />
              </motion.div>
              {/* Markers for 70% and 90% */}
              <div className="absolute inset-0 flex pointer-events-none">
                <div className="w-px h-full bg-white/30 absolute left-[70%]" />
                <div className="w-px h-full bg-white/30 absolute left-[90%]" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Quick Stats Grid */}
      <section className="grid grid-cols-2 gap-4">
        {/* Spent Breakdown Card */}
        <div className="bg-surface-container-lowest rounded-[2.5rem] p-5 shadow-sm border border-surface-container/50 flex flex-col justify-between min-h-[140px]">
          <div className="space-y-1">
            <p className="text-[9px] font-bold text-on-surface-variant/50 uppercase tracking-[0.15em]">Spent Breakdown</p>
            <div className="h-1 w-8 bg-primary/20 rounded-full" />
          </div>
          
          <div className="space-y-2.5">
            <div className="flex flex-col">
              <span className="text-[9px] font-bold text-on-surface-variant/60 uppercase tracking-wider">Commitments</span>
              <span className="text-lg font-extrabold text-primary leading-none">
                {formatCurrency(totalCommitmentsPaid, salaryCurrency)}
              </span>
            </div>
            <div className="flex flex-col">
              <span className="text-[9px] font-bold text-on-surface-variant/60 uppercase tracking-wider">Additional</span>
              <span className="text-lg font-extrabold text-tertiary leading-none">
                {formatCurrency(totalOtherSpent, salaryCurrency)}
              </span>
            </div>
          </div>
        </div>

        {/* Due Next Card */}
        <div className="bg-[#fff4f4] rounded-[2.5rem] p-5 flex flex-col justify-between min-h-[140px] border border-error/5">
          <div className="space-y-1">
            <p className="text-[9px] font-bold text-error/50 uppercase tracking-[0.15em]">Due Next</p>
            <div className="h-1 w-8 bg-error/20 rounded-full" />
          </div>
          
          <div className="space-y-1">
            <p className="text-3xl font-black text-error tracking-tighter">
              {nextDue ? formatCurrency(nextDue.amount, nextDue.currency) : formatCurrency(0, salaryCurrency)}
            </p>
            <p className="text-[10px] font-bold text-error/70 leading-tight">
              {nextDue 
                ? `${nextDue.title} in ${differenceInDays(new Date(nextDue.dueDate!), now)}d` 
                : 'No upcoming dues'}
            </p>
          </div>
        </div>
      </section>

      {/* Manual Savings Quick Action */}
      <section className="bg-surface-container-low rounded-[2rem] p-6 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 bg-tertiary/10 rounded-xl flex items-center justify-center text-tertiary">
            <Wallet className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-primary">Add to Savings</h3>
            <p className="text-[10px] text-on-surface-variant/60">Deduct from current balance</p>
          </div>
        </div>
        <button 
          onClick={() => setShowManualSavings(true)}
          className="w-10 h-10 bg-tertiary text-white rounded-xl flex items-center justify-center shadow-lg"
        >
          <Plus className="w-5 h-5" />
        </button>
      </section>

      {/* Commitment List */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-primary">Active Commitments</h2>
          <span className="text-[10px] font-bold text-on-surface-variant uppercase tracking-widest">
            {userData.obligations.filter(o => o.isCompleted).length} / {userData.obligations.length} Done
          </span>
        </div>

        <div className="space-y-3">
          {sortedObligations.map((obj) => (
            <React.Fragment key={obj.id}>
              <motion.div 
                layout
                className={cn(
                  "p-5 rounded-3xl flex items-center justify-between transition-all border",
                  obj.isCompleted 
                    ? "bg-surface-container-low/50 border-transparent opacity-60" 
                    : "bg-surface-container-lowest border-surface-container shadow-sm"
                )}
              >
                <div className="flex items-center gap-4">
                  <button 
                    onClick={() => toggleObligationComplete(obj.id)}
                    className={cn(
                      "w-10 h-10 rounded-2xl flex items-center justify-center transition-all",
                      obj.isCompleted ? "bg-tertiary text-white" : "bg-surface-container text-on-surface-variant hover:bg-primary/10 hover:text-primary"
                    )}
                  >
                    <CheckCircle2 className={cn("w-6 h-6", !obj.isCompleted && "opacity-20")} />
                  </button>
                  <div>
                    <h3 className={cn("font-bold text-sm", obj.isCompleted && "line-through")}>{obj.title}</h3>
                    <p className="text-[10px] font-bold text-on-surface-variant/60 uppercase tracking-wider">
                      {obj.type} {obj.dueDate ? `• Due ${obj.dueDate}` : ''}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-bold text-primary text-sm">{formatCurrency(obj.amount, obj.currency)}</p>
                  {obj.isCompleted && (
                    <p className="text-[8px] font-bold text-tertiary uppercase tracking-widest mt-1">Settled</p>
                  )}
                </div>
              </motion.div>
              {obj.goalAmount && !obj.isCompleted && (
                <div className="px-5 pb-4 -mt-2">
                  <div className="flex justify-between items-center text-[8px] font-bold uppercase tracking-widest text-on-surface-variant/40 mb-1">
                    <span>Progress to {formatCurrency(obj.goalAmount, obj.currency)}</span>
                    <span>{Math.round((userData.remittances.filter(r => r.obligationId === obj.id).reduce((acc, r) => acc + r.amount, 0) / obj.goalAmount) * 100)}%</span>
                  </div>
                  <div className="h-1 bg-surface-container rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-tertiary/40" 
                      style={{ width: `${Math.min(100, (userData.remittances.filter(r => r.obligationId === obj.id).reduce((acc, r) => acc + r.amount, 0) / obj.goalAmount) * 100)}%` }}
                    />
                  </div>
                </div>
              )}
            </React.Fragment>
          ))}
        </div>
      </section>

      {/* Manual Savings Modal */}
      {showManualSavings && (
        <div className="fixed inset-0 bg-on-surface/20 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-4">
          <motion.div 
            initial={{ y: 100 }}
            animate={{ y: 0 }}
            className="bg-surface w-full max-w-md rounded-[2.5rem] p-8 space-y-8 shadow-2xl"
          >
            <div className="flex justify-between items-center">
              <h2 className="text-2xl font-extrabold text-primary">Add to Savings</h2>
              <button onClick={() => setShowManualSavings(false)} className="p-2 bg-surface-container rounded-full"><Plus className="w-5 h-5 rotate-45" /></button>
            </div>
            
            <div className="space-y-6">
              <div className="space-y-2">
                <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Amount ({salaryCurrency})</label>
                <input 
                  type="number"
                  className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-extrabold text-3xl"
                  placeholder="0.00"
                  value={manualSavingsAmount || ''}
                  onChange={(e) => setManualSavingsAmount(Number(e.target.value))}
                />
                <p className="text-xs text-on-surface-variant/60 italic ml-1">This will be deducted from your remaining balance.</p>
              </div>
            </div>

            <button 
              onClick={handleManualSavings}
              className="w-full py-5 bg-tertiary text-white rounded-full font-bold text-lg shadow-xl shadow-tertiary/20 hover:shadow-2xl transition-all"
            >
              Confirm Savings
            </button>
          </motion.div>
        </div>
      )}
    </div>
  );
};
