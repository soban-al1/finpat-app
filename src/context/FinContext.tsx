import React, { createContext, useContext, useEffect, useState } from 'react';
import { Currency, Obligation, Remittance, ResponsibilityCenter, SalaryFrequency, SavingsLog, UserData } from '../types';
import {
  authApi,
  centersApi,
  obligationsApi,
  profilesApi,
  remittancesApi,
  savingsApi,
  edgeFunctionsApi,
  type Obligation as ApiObligation,
  type Profile as ApiProfile,
  type Remittance as ApiRemittance,
  type ResponsibilityCenter as ApiCenter,
  type SavingsLog as ApiSavings,
} from '../lib/api';
import { convertCurrency } from '../lib/utils';

interface FinContextType {
  userData: UserData;
  updateUserData: (data: Partial<UserData>) => void;
  login: (email: string, name: string, password?: string, mode?: 'login' | 'signup') => Promise<void>;
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
const SESSION_KEY = 'finpat_session';

interface StoredSession {
  accessToken: string;
  refreshToken: string;
  userId: string;
}

function mapProfileToUserData(profile: ApiProfile, prev: UserData): UserData {
  return {
    ...prev,
    isLoggedIn: true,
    onboarded: profile.onboarded,
    workLocation: profile.work_location ?? '',
    familyLocation: profile.family_location ?? '',
    income: {
      amount: Number(profile.income_amount ?? 0),
      currency: (profile.income_currency as Currency) ?? 'USD',
      frequency: (profile.income_frequency as SalaryFrequency) ?? 'monthly',
    },
    user: {
      email: profile.email,
      name: profile.name || profile.email.split('@')[0],
      photoUrl: profile.photo_url ?? undefined,
    },
  };
}

function mapCenter(center: ApiCenter): ResponsibilityCenter {
  return {
    id: center.id,
    name: center.name,
    icon: center.icon,
    color: center.color,
  };
}

function mapObligation(obligation: ApiObligation): Obligation {
  return {
    id: obligation.id,
    title: obligation.title,
    amount: Number(obligation.amount),
    currency: obligation.currency as Currency,
    type: obligation.type,
    dueDate: obligation.due_date ?? undefined,
    goalAmount: obligation.goal_amount ?? undefined,
    isEssential: obligation.is_essential,
    centerId: obligation.center_id,
    isCompleted: obligation.is_completed,
    completedAt: obligation.completed_at ?? undefined,
    hasReminder: obligation.has_reminder,
  };
}

function mapRemittance(remittance: ApiRemittance): Remittance {
  const dateObj = new Date(remittance.date);
  const timeObj = remittance.time ? new Date(`1970-01-01T${remittance.time}`) : new Date();
  return {
    id: remittance.id,
    date: dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
    time: remittance.time
      ? timeObj.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
      : '--:--',
    amount: Number(remittance.amount),
    currency: remittance.currency as Currency,
    targetCurrency: remittance.target_currency as Currency,
    rate: Number(remittance.exchange_rate),
    purpose: remittance.purpose || 'Spending',
    centerId: remittance.center_id,
    obligationId: remittance.obligation_id ?? undefined,
  };
}

function mapSavings(log: ApiSavings): SavingsLog {
  return {
    id: log.id,
    date: log.date,
    amount: Number(log.amount),
    currency: log.currency as Currency,
    type: log.type,
    note: log.note ?? undefined,
  };
}

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
  const [session, setSession] = useState<StoredSession | null>(() => {
    const raw = localStorage.getItem(SESSION_KEY);
    return raw ? (JSON.parse(raw) as StoredSession) : null;
  });

  const fetchAllData = async (activeSession: StoredSession) => {
    const [profileList, centers, obligations, remittances, savings] = await Promise.all([
      profilesApi.getCurrent(activeSession.accessToken, activeSession.userId),
      centersApi.list(activeSession.accessToken, activeSession.userId),
      obligationsApi.list(activeSession.accessToken, activeSession.userId),
      remittancesApi.list(activeSession.accessToken, activeSession.userId, { order: 'created_at.desc' }),
      savingsApi.list(activeSession.accessToken, activeSession.userId, { order: 'created_at.desc' }),
    ]);

    const profile = profileList[0];
    if (!profile) return;

    setUserData((prev) => {
      const mapped = mapProfileToUserData(profile, prev);
      return {
        ...mapped,
        centers: centers.map(mapCenter),
        obligations: obligations.map(mapObligation),
        remittances: remittances.map(mapRemittance),
        savings: savings.map(mapSavings),
      };
    });
  };

  useEffect(() => {
    localStorage.setItem('finpat_data', JSON.stringify(userData));
  }, [userData]);

  useEffect(() => {
    if (!session) return;
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
    void fetchAllData(session);
  }, [session]);

  const updateUserData = (data: Partial<UserData>) => {
    setUserData((prev) => {
      const next = { ...prev, ...data };
      return next;
    });

    if (session) {
      void profilesApi.update(session.accessToken, session.userId, {
        name: data.user?.name,
        photo_url: data.user?.photoUrl,
        onboarded: data.onboarded,
        work_location: data.workLocation,
        family_location: data.familyLocation,
        income_amount: data.income?.amount,
        income_currency: data.income?.currency,
        income_frequency: data.income?.frequency,
      });
    }
  };

  const login = async (email: string, name: string, password?: string, mode: 'login' | 'signup' = 'login') => {
    if (!password) {
      setUserData((prev) => ({
        ...prev,
        isLoggedIn: true,
        user: { email, name },
      }));
      return;
    }

    let accessToken: string | undefined;
    let refreshToken: string | undefined;
    let userId: string | undefined;

    if (mode === 'signup') {
      const authResponse = await authApi.signUp({ email, password, data: { full_name: name } });
      accessToken = authResponse.session?.access_token;
      refreshToken = authResponse.session?.refresh_token;
      userId = authResponse.user.id;
    } else {
      const authResponse = await authApi.signInWithPassword({ email, password });
      accessToken = authResponse.access_token;
      refreshToken = authResponse.refresh_token;
      userId = authResponse.user?.id;
    }

    if (!accessToken || !refreshToken || !userId) {
      throw new Error('Authentication succeeded but no session was returned.');
    }

    setSession({ accessToken, refreshToken, userId });
  };

  const logout = () => {
    if (session) {
      void authApi.signOut(session.accessToken);
    }
    setSession(null);
    localStorage.removeItem(SESSION_KEY);
    setUserData((prev) => ({
      ...prev,
      isLoggedIn: false,
      user: undefined,
    }));
  };

  const addCenter = (center: ResponsibilityCenter) => {
    setUserData((prev) => ({ ...prev, centers: [...prev.centers, center] }));
    if (!session) return;

    void centersApi
      .create(session.accessToken, {
        user_id: session.userId,
        name: center.name,
        icon: center.icon || 'Target',
        color: center.color || '#526772',
        is_default: false,
      })
      .then((rows) => {
        const created = rows[0];
        if (!created) return;
        setUserData((prev) => ({
          ...prev,
          centers: prev.centers.map((c) => (c.id === center.id ? mapCenter(created) : c)),
        }));
      });
  };

  const addObligation = (obligation: Obligation) => {
    setUserData((prev) => ({ ...prev, obligations: [...prev.obligations, obligation] }));
    if (!session) return;

    void obligationsApi
      .create(session.accessToken, {
        user_id: session.userId,
        center_id: obligation.centerId,
        title: obligation.title,
        amount: obligation.amount,
        currency: obligation.currency,
        type: obligation.type,
        due_date: obligation.dueDate ?? null,
        goal_amount: obligation.goalAmount ?? null,
        is_essential: obligation.isEssential,
        is_completed: false,
        completed_at: null,
        has_reminder: obligation.hasReminder,
      })
      .then((rows) => {
        const created = rows[0];
        if (!created) return;
        setUserData((prev) => ({
          ...prev,
          obligations: prev.obligations.map((o) => (o.id === obligation.id ? mapObligation(created) : o)),
        }));
      });
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

    if (!session) return;
    const obligation = userData.obligations.find((o) => o.id === id);
    if (!obligation) return;

    const isBecomingComplete = !obligation.isCompleted;
    void obligationsApi.update(session.accessToken, id, {
      is_completed: isBecomingComplete,
      completed_at: isBecomingComplete ? new Date().toISOString() : null,
    });
  };

  const addRemittance = (remittance: Remittance) => {
    setUserData((prev) => ({ ...prev, remittances: [...prev.remittances, remittance] }));
    if (!session) return;

    const date = new Date();
    const [time] = date.toTimeString().split(' ');
    void remittancesApi
      .create(session.accessToken, {
        user_id: session.userId,
        center_id: remittance.centerId,
        obligation_id: remittance.obligationId ?? null,
        date: date.toISOString().slice(0, 10),
        time,
        amount: remittance.amount,
        currency: remittance.currency,
        target_currency: remittance.targetCurrency,
        exchange_rate: remittance.rate,
        purpose: remittance.purpose,
      })
      .then((rows) => {
        const created = rows[0];
        if (!created) return;
        setUserData((prev) => ({
          ...prev,
          remittances: prev.remittances.map((r) => (r.id === remittance.id ? mapRemittance(created) : r)),
        }));
      });
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

    if (!session) return;
    void savingsApi
      .create(session.accessToken, {
        user_id: session.userId,
        date: now.toISOString().slice(0, 10),
        amount,
        currency: userData.income.currency,
        type,
        note: note ?? null,
      })
      .then((rows) => {
        const created = rows[0];
        if (!created) return;
        setUserData((prev) => ({
          ...prev,
          savings: prev.savings.map((s) => (s.id === newLog.id ? mapSavings(created) : s)),
        }));
      });
  };

  const resetCycle = () => {
    if (session) {
      const cycleMonth = new Date().toISOString().slice(0, 7);
      void edgeFunctionsApi.resetCycle(session.accessToken, { cycle_month: cycleMonth }).then(() => {
        void fetchAllData(session);
      });
      return;
    }

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
    localStorage.removeItem(SESSION_KEY);
    setSession(null);
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
