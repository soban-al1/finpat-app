export type Currency = 'USD' | 'EUR' | 'GBP' | 'AED' | 'INR' | 'PHP' | 'PKR' | 'EGP' | 'MYR' | 'SGD' | 'IDR' | 'THB' | 'VND' | 'BND' | 'MMK' | 'KHR' | 'LAK';
export type SalaryFrequency = 'monthly' | 'bi-weekly' | 'weekly';

export const CURRENCY_FLAGS: Record<Currency, string> = {
  USD: '🇺🇸',
  EUR: '🇪🇺',
  GBP: '🇬🇧',
  AED: '🇦🇪',
  INR: '🇮🇳',
  PHP: '🇵🇭',
  PKR: '🇵🇰',
  EGP: '🇪🇬',
  MYR: '🇲🇾',
  SGD: '🇸🇬',
  IDR: '🇮🇩',
  THB: '🇹🇭',
  VND: '🇻🇳',
  BND: '🇧🇳',
  MMK: '🇲🇲',
  KHR: '🇰🇭',
  LAK: '🇱🇦',
};

export interface Obligation {
  id: string;
  title: string;
  amount: number;
  currency: Currency;
  type: 'monthly' | 'one-time';
  dueDate?: string;
  goalAmount?: number;
  /** Cumulative amount paid toward goalAmount across all past cycles (persists through monthly resets) */
  remittedAmount?: number;
  isEssential: boolean;
  centerId: string;
  isCompleted: boolean;
  completedAt?: string;
  hasReminder: boolean;
}

export interface ResponsibilityCenter {
  id: string;
  name: string;
  icon: string;
  color: string;
}

export interface Remittance {
  id: string;
  date: string;
  time: string;
  amount: number;
  currency: Currency;
  targetCurrency: Currency;
  rate: number;
  purpose: string;
  centerId: string;
  obligationId?: string;
}

export interface SavingsLog {
  id: string;
  date: string;
  amount: number;
  currency: Currency;
  type: 'manual' | 'surplus';
  note?: string;
}

export interface UserData {
  isLoggedIn: boolean;
  user?: {
    email: string;
    name: string;
    photoUrl?: string;
  };
  onboarded: boolean;
  workLocation: string;
  familyLocation: string;
  income: {
    amount: number;
    currency: Currency;
    frequency: SalaryFrequency;
  };
  centers: ResponsibilityCenter[];
  obligations: Obligation[];
  remittances: Remittance[];
  savings: SavingsLog[];
}

export const DEFAULT_CENTERS: ResponsibilityCenter[] = [
  { id: 'household', name: 'Current Household', icon: 'Home', color: '#004d60' },
  { id: 'parents', name: 'Parents', icon: 'Heart', color: '#ba1a1a' },
  { id: 'family', name: 'Spouse/Children', icon: 'Users', color: '#005049' },
  { id: 'property', name: 'Property', icon: 'Building', color: '#526772' },
  { id: 'charity', name: 'Charity', icon: 'Gift', color: '#00677f' },
];
