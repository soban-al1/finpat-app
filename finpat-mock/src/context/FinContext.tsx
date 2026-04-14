import React, { createContext, useContext, useState, useEffect } from 'react';
import { UserData, ResponsibilityCenter, Obligation, Remittance, SavingsLog, SalaryFrequency, Currency } from '../types';
import { convertCurrency } from '../lib/utils';

interface FinContextType {
  userData: UserData;
  updateUserData: (data: Partial<UserData>) => void;
  login: (email: string, name: string) => void;
  logout: () => void;
  addCenter: (center: ResponsibilityCenter) => void;
  addObligation: (obligation: Obligation) => void;
  toggleObligationComplete: (id: string) => void;
  addRemittance: (remittance: Remittance) => void;
  addSavings: (amount: number, type: 'manual' | 'surplus', note?: string) => void;
  resetCycle: () => void;
  resetData: () => void;
}

const INITIAL_DATA: UserData = {
  isLoggedIn: false,
  onboarded: false,
  workLocation: '',
  familyLocation: '',
  income: {
    amount: 0,
    currency: 'USD',
    frequency: 'monthly',
  },
  centers: [],
  obligations: [],
  remittances: [],
  savings: [],
};

const FinContext = createContext<FinContextType | undefined>(undefined);

export const FinProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [userData, setUserData] = useState<UserData>(() => {
    const saved = localStorage.getItem('finpat_data');
    if (saved) {
      const data = JSON.parse(saved);
      // Ensure savings array exists
      if (!data.savings) {
        data.savings = [];
      }
      return data;
    }
    return INITIAL_DATA;
  });

  useEffect(() => {
    localStorage.setItem('finpat_data', JSON.stringify(userData));
  }, [userData]);

  const updateUserData = (data: Partial<UserData>) => {
    setUserData((prev) => ({ ...prev, ...data }));
  };

  const login = (email: string, name: string) => {
    setUserData(prev => ({
      ...prev,
      isLoggedIn: true,
      user: { email, name }
    }));
  };

  const logout = () => {
    setUserData(prev => ({
      ...prev,
      isLoggedIn: false,
      user: undefined
    }));
  };

  const addCenter = (center: ResponsibilityCenter) => {
    setUserData((prev) => ({ ...prev, centers: [...prev.centers, center] }));
  };

  const addObligation = (obligation: Obligation) => {
    setUserData((prev) => ({ ...prev, obligations: [...prev.obligations, obligation] }));
  };

  const toggleObligationComplete = (id: string) => {
    setUserData((prev) => {
      const obligation = prev.obligations.find(o => o.id === id);
      if (!obligation) return prev;

      const isBecomingComplete = !obligation.isCompleted;
      const now = new Date();
      
      const newObligations = prev.obligations.map(o => 
        o.id === id ? { ...o, isCompleted: isBecomingComplete, completedAt: isBecomingComplete ? now.toISOString() : undefined } : o
      );

      let newRemittances = [...prev.remittances];
      if (isBecomingComplete) {
        const newRemittance: Remittance = {
          id: Math.random().toString(36).substr(2, 9),
          date: now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          time: now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
          amount: obligation.amount,
          currency: obligation.currency,
          targetCurrency: obligation.currency,
          rate: 1,
          purpose: obligation.title,
          centerId: obligation.centerId,
          obligationId: obligation.id,
        };
        newRemittances.push(newRemittance);
      } else {
        newRemittances = newRemittances.filter(r => r.obligationId !== id);
      }

      return { ...prev, obligations: newObligations, remittances: newRemittances };
    });
  };

  const addRemittance = (remittance: Remittance) => {
    setUserData((prev) => ({ ...prev, remittances: [...prev.remittances, remittance] }));
  };

  const addSavings = (amount: number, type: 'manual' | 'surplus', note?: string) => {
    const now = new Date();
    const newLog: SavingsLog = {
      id: Math.random().toString(36).substr(2, 9),
      date: now.toISOString(),
      amount,
      currency: userData.income.currency,
      type,
      note,
    };

    setUserData(prev => ({
      ...prev,
      savings: [...prev.savings, newLog],
    }));
  };

  const resetCycle = () => {
    setUserData(prev => {
      const totalIncome = prev.income.amount;
      const totalCommitted = prev.obligations.reduce((acc, obj) => {
        return acc + convertCurrency(obj.amount, obj.currency, prev.income.currency);
      }, 0);
      
      const surplus = Math.max(0, totalIncome - totalCommitted);
      
      const now = new Date();
      const newSavings: SavingsLog[] = [...prev.savings];
      if (surplus > 0) {
        newSavings.push({
          id: Math.random().toString(36).substr(2, 9),
          date: now.toISOString(),
          amount: surplus,
          currency: prev.income.currency,
          type: 'surplus',
          note: `Surplus from ${now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`,
        });
      }

      const resetObligations = prev.obligations.map(o => ({
        ...o,
        isCompleted: false,
        completedAt: undefined,
      }));

      return {
        ...prev,
        obligations: resetObligations,
        remittances: [],
        savings: newSavings,
      };
    });
  };

  const resetData = () => {
    setUserData(INITIAL_DATA);
    localStorage.removeItem('finpat_data');
  };

  return (
    <FinContext.Provider value={{ 
      userData, 
      updateUserData, 
      login, 
      logout, 
      addCenter, 
      addObligation, 
      toggleObligationComplete, 
      addRemittance, 
      addSavings,
      resetCycle,
      resetData 
    }}>
      {children}
    </FinContext.Provider>
  );
};

export const useFinData = () => {
  const context = useContext(FinContext);
  if (!context) throw new Error('useFinData must be used within a FinProvider');
  return context;
};
