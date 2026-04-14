import React from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { formatCurrency, convertCurrency } from '../lib/utils';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { Calendar, AlertTriangle, TrendingDown } from 'lucide-react';

export const Forecast: React.FC = () => {
  const { userData } = useFinData();

  const totalIncome = userData.income.amount;
  const totalObligations = userData.obligations.reduce((acc, o) => {
    return acc + convertCurrency(o.amount, o.currency, userData.income.currency);
  }, 0);

  // Mock data for 6 months
  const data = [
    { name: 'Apr', commitments: totalObligations, remaining: totalIncome - totalObligations },
    { name: 'May', commitments: totalObligations + 200, remaining: totalIncome - (totalObligations + 200) },
    { name: 'Jun', commitments: totalObligations, remaining: totalIncome - totalObligations },
    { name: 'Jul', commitments: totalObligations + 500, remaining: totalIncome - (totalObligations + 500) },
    { name: 'Aug', commitments: totalObligations, remaining: totalIncome - totalObligations },
    { name: 'Sep', commitments: totalObligations, remaining: totalIncome - totalObligations },
  ];

  return (
    <div className="space-y-8 pb-24">
      <header className="space-y-2">
        <h1 className="text-3xl font-extrabold text-primary">Forecast</h1>
        <p className="text-on-surface-variant">Predicting your financial pressure.</p>
      </header>

      {/* Alert */}
      <div className="p-6 bg-error-container rounded-[2rem] flex gap-4 items-start">
        <AlertTriangle className="w-6 h-6 text-error shrink-0" />
        <div className="space-y-1">
          <h3 className="font-bold text-error">Heavy Month Ahead</h3>
          <p className="text-sm text-error/80 leading-relaxed">
            July is expected to have higher commitments due to annual property taxes and travel home. Plan your savings now.
          </p>
        </div>
      </div>

      {/* Chart */}
      <section className="space-y-4">
        <h3 className="font-bold text-lg text-primary">6-Month Pressure View</h3>
        <div className="h-64 bg-surface-container-lowest rounded-[2.5rem] p-6 shadow-sm">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data}>
              <defs>
                <linearGradient id="colorCommit" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#004d60" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#004d60" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <XAxis 
                dataKey="name" 
                axisLine={false} 
                tickLine={false} 
                tick={{ fill: '#3f484c', fontSize: 12, fontWeight: 600 }}
              />
              <Tooltip 
                contentStyle={{ borderRadius: '1rem', border: 'none', boxShadow: '0 8px 24px rgba(0,0,0,0.1)' }}
              />
              <Area 
                type="monotone" 
                dataKey="commitments" 
                stroke="#004d60" 
                strokeWidth={3}
                fillOpacity={1} 
                fill="url(#colorCommit)" 
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </section>

      {/* Monthly Breakdown */}
      <section className="space-y-4">
        <h3 className="font-bold text-lg text-primary">Upcoming Highlights</h3>
        <div className="space-y-3">
          <div className="p-6 bg-surface-container-lowest rounded-3xl flex justify-between items-center">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-surface-container rounded-2xl flex items-center justify-center text-primary">
                <Calendar className="w-6 h-6" />
              </div>
              <div>
                <p className="font-bold text-on-surface">July 2026</p>
                <p className="text-xs text-on-surface-variant">Annual Property Tax</p>
              </div>
            </div>
            <p className="font-bold text-error">+{formatCurrency(500, userData.income.currency)}</p>
          </div>
          
          <div className="p-6 bg-surface-container-lowest rounded-3xl flex justify-between items-center">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-surface-container rounded-2xl flex items-center justify-center text-primary">
                <TrendingDown className="w-6 h-6" />
              </div>
              <div>
                <p className="font-bold text-on-surface">August 2026</p>
                <p className="text-xs text-on-surface-variant">Expected Recovery</p>
              </div>
            </div>
            <p className="font-bold text-tertiary">Normal</p>
          </div>
        </div>
      </section>
    </div>
  );
};
