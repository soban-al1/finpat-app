import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { Currency, ResponsibilityCenter, Obligation, CURRENCY_FLAGS } from '../types';
import { Plus, X, ChevronRight, Trash2, Calendar, Repeat, CheckCircle2, Target } from 'lucide-react';
import { formatCurrency, cn, convertCurrency } from '../lib/utils';

export const Centers: React.FC = () => {
  const { userData, addCenter, addObligation, toggleObligationComplete } = useFinData();
  const [showWizard, setShowWizard] = useState(false);
  const [wizardStep, setWizardStep] = useState<'center' | 'obligation'>('center');
  const [selectedCenterId, setSelectedCenterId] = useState<string | null>(null);

  const [newCenter, setNewCenter] = useState({ name: '', color: '#004d60' });
  const [newObligation, setNewObligation] = useState({
    title: '',
    amount: 0,
    goalAmount: 0,
    hasGoal: false,
    currency: userData.income.currency,
    type: 'monthly' as 'monthly' | 'one-time',
    dueDate: '',
    isEssential: true,
  });

  const handleStartWizard = (centerId?: string) => {
    if (centerId) {
      setSelectedCenterId(centerId);
      setWizardStep('obligation');
    } else {
      setSelectedCenterId(null);
      setWizardStep('center');
    }
    setShowWizard(true);
  };

  const handleCenterNext = () => {
    if (!newCenter.name) return;
    const centerId = Math.random().toString(36).substr(2, 9);
    addCenter({
      id: centerId,
      name: newCenter.name,
      icon: 'Target',
      color: newCenter.color,
    });
    setSelectedCenterId(centerId);
    setWizardStep('obligation');
  };

  const handleAddObligation = (addAnother = false) => {
    if (!newObligation.title || !selectedCenterId) return;
    addObligation({
      id: Math.random().toString(36).substr(2, 9),
      title: newObligation.title,
      amount: newObligation.amount,
      goalAmount: newObligation.goalAmount || undefined,
      currency: newObligation.currency as Currency,
      type: newObligation.type,
      dueDate: newObligation.type === 'one-time' ? newObligation.dueDate : undefined,
      isEssential: newObligation.isEssential,
      centerId: selectedCenterId,
      isCompleted: false,
      hasReminder: true,
    });
    
    setNewObligation({ 
      title: '', 
      amount: 0, 
      goalAmount: 0,
      hasGoal: false,
      currency: userData.income.currency, 
      type: 'monthly', 
      dueDate: '', 
      isEssential: true 
    });

    if (!addAnother) {
      setShowWizard(false);
      setWizardStep('center');
    }
  };

  return (
    <div className="space-y-8 pb-32">
      <header className="space-y-2">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-extrabold text-primary tracking-tight">Commitments</h1>
          <button 
            onClick={() => handleStartWizard()}
            className="w-12 h-12 bg-primary text-white rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-105 transition-transform"
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
        <p className="text-on-surface-variant text-sm font-medium">Manage your financial responsibilities and goals.</p>
      </header>

      <div className="grid grid-cols-1 gap-6">
        {userData.centers.map((center) => {
          const obligations = userData.obligations.filter(o => o.centerId === center.id);
          const totalInBase = obligations.reduce((acc, o) => {
            return acc + convertCurrency(o.amount, o.currency, userData.income.currency);
          }, 0);

          return (
            <div key={center.id} className="bg-surface-container-lowest rounded-[2.5rem] p-6 shadow-sm space-y-8 border border-surface-container/50 overflow-hidden relative">
              {/* Decorative accent */}
              <div className="absolute top-0 left-0 w-full h-1.5" style={{ backgroundColor: center.color }} />

              <div className="flex justify-between items-center">
                <div className="flex items-center gap-4">
                  <div 
                    className="w-14 h-14 rounded-[1.25rem] flex items-center justify-center text-white shadow-lg"
                    style={{ backgroundColor: center.color }}
                  >
                    <Target className="w-7 h-7" />
                  </div>
                  <div className="space-y-0.5">
                    <h3 className="text-xl font-black text-primary tracking-tight">{center.name}</h3>
                    <p className="text-[10px] font-bold text-on-surface-variant/50 uppercase tracking-widest">Responsibility Center</p>
                  </div>
                </div>
                <button 
                  onClick={() => handleStartWizard(center.id)}
                  className="w-10 h-10 bg-primary/5 text-primary rounded-xl flex items-center justify-center hover:bg-primary/10 transition-all"
                >
                  <Plus className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-6">
                {obligations.map((o) => {
                  const totalPaidForThis = userData.remittances
                    .filter(r => r.obligationId === o.id)
                    .reduce((acc, r) => acc + r.amount, 0);
                  const progress = o.goalAmount ? (totalPaidForThis / o.goalAmount) * 100 : 0;

                  return (
                    <div key={o.id} className={cn("group relative space-y-4 p-4 rounded-3xl transition-all border border-transparent hover:bg-surface-container-low/30 hover:border-surface-container", o.isCompleted && "opacity-60")}>
                      <div className="flex justify-between items-start gap-4">
                        <div className="flex items-start gap-4">
                          <button 
                            onClick={() => toggleObligationComplete(o.id)}
                            className={cn(
                              "w-7 h-7 rounded-xl flex items-center justify-center transition-all mt-0.5 shrink-0 shadow-sm",
                              o.isCompleted ? "bg-tertiary text-white" : "bg-surface-container text-on-surface-variant/20 border border-surface-container hover:border-primary/30"
                            )}
                          >
                            {o.isCompleted ? <CheckCircle2 className="w-4 h-4" /> : <div className="w-2 h-2 rounded-full bg-on-surface-variant/10" />}
                          </button>
                          <div className="space-y-1.5">
                            <div className="flex items-center gap-2 flex-wrap">
                              <span className={cn("text-on-surface font-extrabold text-base tracking-tight", o.isCompleted && "line-through opacity-50")}>{o.title}</span>
                              <div className="flex items-center gap-1.5">
                                {o.type === 'monthly' ? (
                                  <div className="p-1 bg-primary/5 rounded-md"><Repeat className="w-3 h-3 text-primary/40" /></div>
                                ) : (
                                  <div className="p-1 bg-primary/5 rounded-md"><Calendar className="w-3 h-3 text-primary/40" /></div>
                                )}
                                {o.isEssential && (
                                  <span className="text-[8px] font-black uppercase tracking-widest bg-error/10 text-error px-1.5 py-0.5 rounded-full">Essential</span>
                                )}
                              </div>
                            </div>
                            <div className="flex items-center gap-2 text-[9px] font-bold uppercase tracking-[0.1em] text-on-surface-variant/40">
                              <span className="bg-surface-container px-2 py-0.5 rounded-md">{o.type}</span>
                              {o.dueDate && <span className="text-error/60 font-black">• Due {o.dueDate}</span>}
                            </div>
                          </div>
                        </div>
                        <div className="text-right shrink-0">
                          <p className={cn("font-black text-primary text-lg leading-none tracking-tighter", o.isCompleted && "opacity-50")}>
                            {formatCurrency(o.amount, o.currency)}
                          </p>
                          {o.currency !== userData.income.currency && (
                            <p className="text-[10px] font-bold text-on-surface-variant/40 mt-1">
                              ≈ {formatCurrency(convertCurrency(o.amount, o.currency, userData.income.currency), userData.income.currency)}
                            </p>
                          )}
                        </div>
                      </div>

                      {o.goalAmount && (
                        <div className="space-y-2.5 pl-11">
                          <div className="flex justify-between items-end">
                            <div className="space-y-0.5">
                              <p className="text-[8px] font-black uppercase tracking-widest text-on-surface-variant/40">Settlement Goal</p>
                              <p className="text-xs font-extrabold text-on-surface-variant">{formatCurrency(o.goalAmount, o.currency)}</p>
                            </div>
                            <div className="text-right">
                              <p className="text-xs font-black text-tertiary">{Math.round(progress)}%</p>
                            </div>
                          </div>
                          <div className="relative h-2 bg-surface-container rounded-full overflow-hidden">
                            <motion.div 
                              initial={{ width: 0 }}
                              animate={{ width: `${Math.min(100, progress)}%` }}
                              className="h-full bg-tertiary relative"
                            >
                              <div className="absolute inset-0 bg-gradient-to-r from-white/0 via-white/20 to-white/0" />
                            </motion.div>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
                {obligations.length === 0 && (
                  <button 
                    onClick={() => handleStartWizard(center.id)}
                    className="w-full py-12 text-center space-y-3 bg-surface-container-low/20 rounded-[2rem] border border-dashed border-surface-container hover:bg-surface-container-low/40 transition-all group/empty"
                  >
                    <div className="w-12 h-12 bg-surface-container rounded-2xl flex items-center justify-center mx-auto text-on-surface-variant/20 group-hover/empty:scale-110 group-hover/empty:text-primary/40 transition-all">
                      <Plus className="w-6 h-6" />
                    </div>
                    <p className="text-xs font-bold text-on-surface-variant/40 uppercase tracking-widest group-hover/empty:text-primary/60 transition-all">No active commitments</p>
                  </button>
                )}
              </div>

              <div className="pt-6 border-t border-surface-container/50 flex justify-between items-center">
                <div className="space-y-1">
                  <p className="text-[9px] font-black uppercase tracking-[0.2em] text-on-surface-variant/40">Monthly Impact</p>
                  <p className="text-[10px] font-bold text-primary/40">Converted to {userData.income.currency}</p>
                </div>
                <div className="text-right">
                  <span className="text-3xl font-black text-primary tracking-tighter">
                    {formatCurrency(totalInBase, userData.income.currency)}
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Unified Wizard Modal */}
      {showWizard && (
        <div className="fixed inset-0 bg-on-surface/40 backdrop-blur-md z-50 flex items-end sm:items-center justify-center p-4">
          <motion.div 
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className="bg-surface w-full max-w-md rounded-[2.5rem] p-8 space-y-8 shadow-2xl overflow-y-auto max-h-[90vh] border border-surface-container"
          >
            <div className="flex justify-between items-center">
              <div className="space-y-1.5">
                <h2 className="text-3xl font-black text-primary tracking-tight leading-none">
                  {wizardStep === 'center' ? 'New Center' : 'Add Commitment'}
                </h2>
                <div className="flex items-center gap-2">
                  <div className="px-2 py-0.5 bg-primary/10 text-primary rounded-full text-[8px] font-black uppercase tracking-widest">
                    Step {wizardStep === 'center' ? '1/2' : '2/2'}
                  </div>
                  <p className="text-[10px] font-bold text-on-surface-variant/40 uppercase tracking-widest">
                    {wizardStep === 'center' ? 'Define responsibility' : 'Set the details'}
                  </p>
                </div>
              </div>
              <button 
                onClick={() => {
                  setShowWizard(false);
                  setWizardStep('center');
                }} 
                className="w-10 h-10 bg-surface-container rounded-xl flex items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-all"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            {wizardStep === 'center' ? (
              <div className="space-y-8">
                <div className="space-y-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Center Name</label>
                    <input 
                      type="text"
                      className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium"
                      placeholder="e.g. Parents' Support"
                      value={newCenter.name}
                      onChange={(e) => setNewCenter({ ...newCenter, name: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Theme Color</label>
                    <div className="flex justify-between p-2 bg-surface-container rounded-2xl">
                      {['#004d60', '#ba1a1a', '#005049', '#526772', '#00677f'].map((c) => (
                        <button 
                          key={c}
                          onClick={() => setNewCenter({ ...newCenter, color: c })}
                          className={cn(
                            "w-12 h-12 rounded-xl transition-all flex items-center justify-center",
                            newCenter.color === c ? "ring-4 ring-white shadow-lg scale-110" : "opacity-60"
                          )}
                          style={{ backgroundColor: c }}
                        >
                          {newCenter.color === c && <Plus className="w-5 h-5 text-white" />}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>

                <button 
                  onClick={handleCenterNext}
                  className="w-full py-5 bg-primary text-white rounded-full font-bold text-lg shadow-xl shadow-primary/20 hover:shadow-2xl transition-all flex items-center justify-center gap-2"
                >
                  Next: Add Commitments <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            ) : (
              <div className="space-y-8">
                <div className="space-y-6">
                  <div className="space-y-2">
                    <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Title</label>
                    <input 
                      type="text"
                      className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium"
                      placeholder="e.g. Monthly Rent"
                      value={newObligation.title}
                      onChange={(e) => setNewObligation({ ...newObligation, title: e.target.value })}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Type</label>
                      <select 
                        className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-bold appearance-none"
                        value={newObligation.type}
                        onChange={(e) => setNewObligation({ ...newObligation, type: e.target.value as 'monthly' | 'one-time' })}
                      >
                        <option value="monthly">Monthly</option>
                        <option value="one-time">One-time</option>
                      </select>
                    </div>
                    {newObligation.type === 'one-time' && (
                      <div className="space-y-2">
                        <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Due Date</label>
                        <input 
                          type="date"
                          className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-bold"
                          value={newObligation.dueDate}
                          onChange={(e) => setNewObligation({ ...newObligation, dueDate: e.target.value })}
                        />
                      </div>
                    )}
                  </div>

                  <div className="flex gap-4 items-end">
                    <div className="flex-1 space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Monthly Amount</label>
                      <input 
                        type="number"
                        className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-bold text-xl"
                        placeholder="0"
                        value={newObligation.amount || ''}
                        onChange={(e) => setNewObligation({ ...newObligation, amount: Number(e.target.value) })}
                      />
                    </div>
                    <div className="w-36 space-y-2">
                      <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1 block h-4">Currency</label>
                      <div className="relative">
                        <select 
                          className="w-full p-5 bg-surface-container rounded-2xl focus:outline-none font-bold appearance-none"
                          value={newObligation.currency}
                          onChange={(e) => setNewObligation({ ...newObligation, currency: e.target.value as Currency })}
                        >
                          {Object.keys(CURRENCY_FLAGS).map(c => (
                            <option key={c} value={c}>{CURRENCY_FLAGS[c as Currency]} {c}</option>
                          ))}
                        </select>
                        <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant/40">
                          <ChevronRight className="w-4 h-4 rotate-90" />
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4 p-6 bg-surface-container-low/30 rounded-3xl border border-surface-container/50">
                    <div className="flex justify-between items-center">
                      <div className="space-y-0.5">
                        <label className="text-xs font-black uppercase tracking-widest text-primary">Settlement Goal</label>
                        <p className="text-[10px] text-on-surface-variant/60 font-medium">Track progress towards a total amount</p>
                      </div>
                      <button 
                        onClick={() => setNewObligation({ ...newObligation, hasGoal: !newObligation.hasGoal })}
                        className={cn(
                          "w-12 h-6 rounded-full transition-all relative",
                          newObligation.hasGoal ? "bg-primary" : "bg-surface-container-high"
                        )}
                      >
                        <motion.div 
                          animate={{ x: newObligation.hasGoal ? 24 : 4 }}
                          className="absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm"
                        />
                      </button>
                    </div>

                    <AnimatePresence>
                      {newObligation.hasGoal && (
                        <motion.div 
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: 'auto', opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          className="overflow-hidden"
                        >
                          <div className="pt-4 space-y-2">
                            <label className="text-[10px] font-black uppercase tracking-widest text-on-surface-variant/60 ml-1">End Goal Amount</label>
                            <div className="relative">
                              <input 
                                type="number"
                                className="w-full p-5 pr-20 bg-surface-container rounded-2xl focus:outline-none font-bold text-xl"
                                placeholder="e.g. 50000"
                                value={newObligation.goalAmount || ''}
                                onChange={(e) => setNewObligation({ ...newObligation, goalAmount: Number(e.target.value) })}
                              />
                              <div className="absolute right-5 top-1/2 -translate-y-1/2 text-on-surface-variant/40 font-bold">
                                {newObligation.currency}
                              </div>
                            </div>
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                </div>

                <div className="flex flex-col gap-3">
                  <button 
                    onClick={() => handleAddObligation(false)}
                    className="w-full py-5 bg-primary text-white rounded-full font-bold text-lg shadow-xl shadow-primary/20 hover:shadow-2xl transition-all"
                  >
                    Finish & Save
                  </button>
                  <button 
                    onClick={() => handleAddObligation(true)}
                    className="w-full py-4 bg-surface-container text-primary rounded-full font-bold text-sm hover:bg-primary/5 transition-all"
                  >
                    Save & Add Another
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </div>
  );
};
