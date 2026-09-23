import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { Currency, DEFAULT_CENTERS, SalaryFrequency, ResponsibilityCenter, CURRENCY_FLAGS } from '../types';
import { cn } from '../lib/utils';
import { ChevronRight, ChevronLeft, Check, MapPin, Heart, Calendar, Repeat, Clock, X } from 'lucide-react';

// Maps the names that the backend seeds on signup → the corresponding
// frontend DEFAULT_CENTERS id, so we can detect which seeded centers the
// user did NOT select and remove them from the database.
const SEEDED_NAME_TO_FRONTEND_ID: Record<string, string> = {
  'Household': 'household',
  'Parents': 'parents',
  'Spouse/Children': 'family',
  'Property': 'property',
  'Charity': 'charity',
};

export const Onboarding: React.FC = () => {
  const { updateUserData, userData, addCenter, deleteCenter } = useFinData();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    workLocation: '',
    familyLocation: '',
    incomeAmount: 0,
    incomeCurrency: 'USD' as Currency,
    incomeFrequency: 'monthly' as SalaryFrequency,
    selectedCenters: [] as string[],
    customCenters: [] as ResponsibilityCenter[],
  });
  const [newCenterName, setNewCenterName] = useState('');

  const nextStep = () => setStep((s) => s + 1);
  const prevStep = () => setStep((s) => s - 1);

  const handleComplete = () => {
    // Remove any seeded centers the user did NOT select, so the Commitments
    // screen only shows what the user explicitly chose during onboarding.
    userData.centers.forEach((dbCenter) => {
      const frontendId = SEEDED_NAME_TO_FRONTEND_ID[dbCenter.name];
      const wasSelected = frontendId
        ? formData.selectedCenters.includes(frontendId)
        : false; // unknown / leftover from a prior session — clean up
      if (!wasSelected) {
        deleteCenter(dbCenter.id);
      }
    });

    // Persist any custom centers the user created during onboarding.
    formData.customCenters.forEach((c) => addCenter(c));

    const defaultSelected = DEFAULT_CENTERS.filter(c => formData.selectedCenters.includes(c.id));
    const centers = [...defaultSelected, ...formData.customCenters];

    updateUserData({
      onboarded: true,
      workLocation: formData.workLocation,
      familyLocation: formData.familyLocation,
      income: {
        amount: formData.incomeAmount,
        currency: formData.incomeCurrency,
        frequency: formData.incomeFrequency,
      },
      centers,
    });
  };

  const addCustomCenter = () => {
    if (!newCenterName.trim()) return;
    const newCenter: ResponsibilityCenter = {
      id: Math.random().toString(36).substr(2, 9),
      name: newCenterName.trim(),
      icon: 'Target',
      color: '#526772',
    };
    setFormData(prev => ({
      ...prev,
      customCenters: [...prev.customCenters, newCenter]
    }));
    setNewCenterName('');
  };

  const renderStep = () => {
    switch (step) {
      case 1:
        return (
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="space-y-8"
          >
            <div className="space-y-2">
              <h1 className="text-4xl font-extrabold text-primary">Where is your life?</h1>
              <p className="text-on-surface-variant">Let's set the context for your financial journey.</p>
            </div>
            
            <div className="space-y-6">
              <div className="space-y-2">
                <label className="text-sm font-medium text-on-surface-variant uppercase tracking-wider">Where do you work?</label>
                <div className="relative">
                  <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-primary w-5 h-5" />
                  <input 
                    type="text"
                    placeholder="e.g. Dubai, London, New York"
                    className="w-full pl-12 pr-4 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                    value={formData.workLocation}
                    onChange={(e) => setFormData({ ...formData, workLocation: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-on-surface-variant uppercase tracking-wider">Where do you usually send money?</label>
                <div className="relative">
                  <Heart className="absolute left-4 top-1/2 -translate-y-1/2 text-primary w-5 h-5" />
                  <input 
                    type="text"
                    placeholder="e.g. Mumbai, Manila, Cairo"
                    className="w-full pl-12 pr-4 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                    value={formData.familyLocation}
                    onChange={(e) => setFormData({ ...formData, familyLocation: e.target.value })}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        );
      case 2:
        return (
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="space-y-8"
          >
            <div className="space-y-2">
              <h1 className="text-4xl font-extrabold text-primary">Your Income</h1>
              <p className="text-on-surface-variant">What's your monthly fuel?</p>
            </div>
            
            <div className="space-y-8">
              <div className="space-y-4">
                <label className="text-xs font-bold text-on-surface-variant uppercase tracking-widest">Salary Amount</label>
                <div className="flex gap-4">
                  <div className="flex-1 bg-surface-container rounded-3xl p-6 flex items-center">
                    <input 
                      type="number"
                      placeholder="0.00"
                      className="w-full bg-transparent text-3xl font-extrabold focus:outline-none placeholder:text-on-surface-variant/20"
                      value={formData.incomeAmount || ''}
                      onChange={(e) => setFormData({ ...formData, incomeAmount: Number(e.target.value) })}
                    />
                  </div>
                  <div className="w-36 bg-[#e0f2f1] rounded-3xl p-6 flex items-center justify-between">
                    <select 
                      className="w-full bg-transparent font-bold text-lg focus:outline-none appearance-none text-[#004d60]"
                      value={formData.incomeCurrency}
                      onChange={(e) => setFormData({ ...formData, incomeCurrency: e.target.value as Currency })}
                    >
                      {Object.keys(CURRENCY_FLAGS).map(c => (
                        <option key={c} value={c}>{CURRENCY_FLAGS[c as Currency]} {c}</option>
                      ))}
                    </select>
                    <ChevronRight className="w-5 h-5 text-[#004d60] rotate-90" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <label className="text-xs font-bold text-on-surface-variant uppercase tracking-widest">Frequency</label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { id: 'monthly', label: 'Monthly', icon: Calendar },
                    { id: 'bi-weekly', label: 'Bi-weekly', icon: Repeat },
                    { id: 'weekly', label: 'Weekly', icon: Clock },
                  ].map((freq) => (
                    <button
                      key={freq.id}
                      onClick={() => setFormData({ ...formData, incomeFrequency: freq.id as SalaryFrequency })}
                      className={cn(
                        "flex flex-col items-center justify-center p-6 rounded-3xl transition-all gap-3 border-2",
                        formData.incomeFrequency === freq.id
                          ? "bg-[#004d60] text-white border-[#004d60] shadow-lg"
                          : "bg-surface-container-lowest text-on-surface-variant border-transparent hover:border-surface-container"
                      )}
                    >
                      <freq.icon className={cn("w-8 h-8", formData.incomeFrequency === freq.id ? "text-white" : "text-on-surface-variant/40")} />
                      <span className="text-xs font-bold">{freq.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        );
      case 3:
        return (
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="space-y-8"
          >
            <div className="space-y-2">
              <h1 className="text-4xl font-extrabold text-primary">Responsibilities</h1>
              <p className="text-on-surface-variant">Who or what do you support?</p>
            </div>
            
            <div className="space-y-6">
              <div className="grid grid-cols-1 gap-3">
                {DEFAULT_CENTERS.map((center) => (
                  <button
                    key={center.id}
                    onClick={() => {
                      const selected = formData.selectedCenters.includes(center.id)
                        ? formData.selectedCenters.filter(id => id !== center.id)
                        : [...formData.selectedCenters, center.id];
                      setFormData({ ...formData, selectedCenters: selected });
                    }}
                    className={cn(
                      "flex items-center justify-between p-5 rounded-2xl transition-all text-left",
                      formData.selectedCenters.includes(center.id)
                        ? "bg-primary text-white shadow-lg"
                        : "bg-surface-container hover:bg-surface-container-low"
                    )}
                  >
                    <span className="font-semibold text-lg">{center.name}</span>
                    {formData.selectedCenters.includes(center.id) && <Check className="w-5 h-5" />}
                  </button>
                ))}
                
                {formData.customCenters.map((center) => (
                  <div
                    key={center.id}
                    className="flex items-center justify-between p-5 rounded-2xl bg-primary text-white shadow-lg group"
                  >
                    <span className="font-semibold text-lg">{center.name}</span>
                    <button 
                      onClick={() => setFormData(prev => ({
                        ...prev,
                        customCenters: prev.customCenters.filter(c => c.id !== center.id)
                      }))}
                      className="p-2 hover:bg-white/20 rounded-full transition-colors"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                ))}
              </div>

              <div className="space-y-3">
                <label className="text-xs font-bold text-on-surface-variant uppercase tracking-widest ml-1">Add Custom Responsibility</label>
                <div className="flex gap-2">
                  <input 
                    type="text"
                    placeholder="e.g. Education, Business, Savings"
                    className="flex-1 px-5 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                    value={newCenterName}
                    onChange={(e) => setNewCenterName(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && addCustomCenter()}
                  />
                  <button 
                    onClick={addCustomCenter}
                    className="px-6 py-4 bg-primary/10 text-primary rounded-2xl font-bold hover:bg-primary/20 transition-all"
                  >
                    Add
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col p-6 max-w-lg mx-auto">
      <div className="flex-1 flex flex-col justify-center">
        <div className="mb-12 flex gap-2">
          {[1, 2, 3].map((i) => (
            <div 
              key={i} 
              className={cn(
                "h-1.5 flex-1 rounded-full transition-all",
                i <= step ? "bg-primary" : "bg-surface-container"
              )}
            />
          ))}
        </div>

        <AnimatePresence mode="wait">
          {renderStep()}
        </AnimatePresence>
      </div>

      <div className="mt-12 flex gap-4">
        {step > 1 && (
          <button 
            onClick={prevStep}
            className="p-4 rounded-full bg-surface-container text-primary hover:bg-surface-container-low transition-all"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
        )}
        <button 
          onClick={step === 3 ? handleComplete : nextStep}
          className="flex-1 bg-primary text-white py-4 px-8 rounded-full font-bold text-lg shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2"
        >
          {step === 3 ? 'Get Started' : 'Continue'}
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};
