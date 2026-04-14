import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// Mock exchange rates relative to USD
const MOCK_RATES: Record<string, number> = {
  USD: 1,
  EUR: 0.92,
  GBP: 0.79,
  AED: 3.67,
  INR: 83.35,
  PHP: 56.12,
  PKR: 278.50,
  EGP: 47.50,
  MYR: 4.75,
  SGD: 1.35,
  IDR: 15800,
  THB: 36.5,
  VND: 25000,
  BND: 1.35,
  MMK: 3500,
  KHR: 4000,
  LAK: 21000,
};

export function convertCurrency(amount: number, from: string, to: string): number {
  if (from === to) return amount;
  const amountInUsd = amount / (MOCK_RATES[from] || 1);
  return amountInUsd * (MOCK_RATES[to] || 1);
}
