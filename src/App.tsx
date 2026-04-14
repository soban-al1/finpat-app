import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { FinProvider, useFinData } from './context/FinContext';
import { Onboarding } from './screens/Onboarding';
import { Dashboard } from './screens/Dashboard';
import { MonthlyPlan } from './screens/MonthlyPlan';
import { Centers } from './screens/Centers';
import { RemittanceLog } from './screens/RemittanceLog';
import { Forecast } from './screens/Forecast';
import { Savings } from './screens/Savings';
import { Settings } from './screens/Settings';
import { AuthScreen } from './screens/AuthScreen';
import { LayoutGrid, Target, Send, BarChart3, User, Settings as SettingsIcon, X, Wallet } from 'lucide-react';
import { cn } from './lib/utils';

const AppContent: React.FC = () => {
  const { userData } = useFinData();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [authType, setAuthType] = useState<'login' | 'signup'>('login');
  const [showSettings, setShowSettings] = useState(false);

  if (!userData.isLoggedIn) {
    return (
      <AnimatePresence mode="wait">
        <motion.div
          key={authType}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
        >
          <AuthScreen 
            type={authType} 
            onSwitch={() => setAuthType(authType === 'login' ? 'signup' : 'login')} 
          />
        </motion.div>
      </AnimatePresence>
    );
  }

  if (!userData.onboarded) {
    return <Onboarding />;
  }

  const renderScreen = () => {
    switch (activeTab) {
      case 'dashboard': return <Dashboard />;
      case 'commitments': return <Centers />;
      case 'remittance': return <RemittanceLog />;
      case 'savings': return <Savings />;
      case 'forecast': return <Forecast />;
      default: return <Dashboard />;
    }
  };

  const navItems = [
    { id: 'dashboard', icon: LayoutGrid, label: 'Home' },
    { id: 'commitments', icon: Target, label: 'Commitments' },
    { id: 'remittance', icon: Send, label: 'Spent' },
    { id: 'savings', icon: Wallet, label: 'Savings' },
    { id: 'forecast', icon: BarChart3, label: 'Forecast' },
  ];

  return (
    <div className="min-h-screen bg-surface flex flex-col">
      {/* Top Bar */}
      <header className="px-6 py-4 flex items-center justify-between sticky top-0 glass z-30">
        <button 
          onClick={() => setShowSettings(true)}
          className="flex items-center gap-3 group"
        >
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary border-2 border-transparent group-hover:border-primary/20 transition-all">
            {userData.user?.photoUrl ? (
              <img src={userData.user.photoUrl} alt="Profile" className="w-full h-full rounded-full object-cover" />
            ) : (
              <User className="w-5 h-5" />
            )}
          </div>
          <div className="text-left hidden sm:block">
            <p className="text-xs font-bold text-on-surface-variant uppercase tracking-widest">Architect</p>
            <p className="text-sm font-bold text-primary">{userData.user?.name || 'User'}</p>
          </div>
        </button>
        <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center shadow-lg shadow-primary/20">
          <span className="text-white font-display font-extrabold text-sm">FP</span>
        </div>
      </header>

      <main className="flex-1 max-w-lg mx-auto w-full p-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
          >
            {renderScreen()}
          </motion.div>
        </AnimatePresence>
      </main>

      {/* Settings Sidebar/Overlay */}
      <AnimatePresence>
        {showSettings && (
          <div className="fixed inset-0 z-50 flex">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowSettings(false)}
              className="absolute inset-0 bg-on-surface/20 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="relative w-full max-w-[280px] bg-surface h-full shadow-2xl p-6 flex flex-col"
            >
              <div className="flex justify-between items-center mb-8">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl bg-primary flex items-center justify-center text-white shadow-lg">
                    <User className="w-6 h-6" />
                  </div>
                  <div>
                    <h2 className="font-display font-extrabold text-primary">{userData.user?.name}</h2>
                    <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-widest">Settings</p>
                  </div>
                </div>
                <button 
                  onClick={() => setShowSettings(false)}
                  className="p-2 hover:bg-surface-container rounded-full transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="flex-1 overflow-y-auto">
                <Settings />
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-0 right-0 glass border-t border-surface-container-low px-4 py-3 pb-8 z-40">
        <div className="max-w-lg mx-auto flex justify-around items-center">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={cn(
                "flex flex-col items-center gap-1 transition-all duration-300",
                activeTab === item.id ? "text-primary scale-110" : "text-on-surface-variant opacity-60"
              )}
            >
              <item.icon className={cn("w-6 h-6", activeTab === item.id && "fill-primary/10")} />
              <span className="text-[10px] font-bold uppercase tracking-wider">{item.label}</span>
            </button>
          ))}
        </div>
      </nav>
    </div>
  );
};

export default function App() {
  return (
    <FinProvider>
      <AppContent />
    </FinProvider>
  );
}
