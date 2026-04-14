import React, { useState } from 'react';
import { motion } from 'motion/react';
import { useFinData } from '../context/FinContext';
import { Mail, Lock, Chrome, ArrowRight } from 'lucide-react';
import { cn } from '../lib/utils';

interface AuthProps {
  onSwitch: () => void;
  type: 'login' | 'signup';
}

export const AuthScreen: React.FC<AuthProps> = ({ onSwitch, type }) => {
  const { login } = useFinData();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      await login(email, name || email.split('@')[0], password, type);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Authentication failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleGoogleClick = async () => {
    setError('Google OAuth flow is not wired yet.');
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col p-8 max-w-lg mx-auto">
      <div className="flex-1 flex flex-col justify-center space-y-12">
        <div className="space-y-4">
          <div className="w-16 h-16 bg-primary rounded-[2rem] flex items-center justify-center shadow-2xl shadow-primary/20">
            <span className="text-white font-display font-extrabold text-2xl">FP</span>
          </div>
          <div className="space-y-2">
            <h1 className="text-4xl font-extrabold text-primary">
              {type === 'login' ? 'Welcome Back' : 'Create Account'}
            </h1>
            <p className="text-on-surface-variant leading-relaxed">
              {type === 'login' 
                ? 'Your financial architect is ready to continue the journey.' 
                : 'Start building your financial clarity today.'}
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-4">
            {type === 'signup' && (
              <div className="space-y-2">
                <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Full Name</label>
                <div className="relative">
                  <input 
                    type="text"
                    required
                    placeholder="John Doe"
                    className="w-full px-6 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                </div>
              </div>
            )}
            
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-on-surface-variant/40" />
                <input 
                  type="email"
                  required
                  placeholder="name@example.com"
                  className="w-full pl-14 pr-6 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-bold uppercase tracking-widest text-on-surface-variant ml-1">Password</label>
              <div className="relative">
                <Lock className="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-on-surface-variant/40" />
                <input 
                  type="password"
                  required
                  placeholder="••••••••"
                  className="w-full pl-14 pr-6 py-4 bg-surface-container rounded-2xl focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>
          </div>

          <button 
            type="submit"
            disabled={isSubmitting}
            className="w-full py-5 bg-primary text-white rounded-full font-bold text-lg shadow-xl shadow-primary/20 hover:shadow-2xl transition-all flex items-center justify-center gap-2 group"
          >
            {isSubmitting ? 'Please wait...' : type === 'login' ? 'Sign In' : 'Create Account'}
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </button>
          {error && <p className="text-sm text-error font-medium">{error}</p>}
        </form>

        <div className="space-y-6">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-surface-container"></div>
            </div>
            <div className="relative flex justify-center text-xs uppercase tracking-widest font-bold">
              <span className="bg-surface px-4 text-on-surface-variant">Or continue with</span>
            </div>
          </div>

          <button 
            onClick={handleGoogleClick}
            className="w-full flex items-center justify-center gap-3 py-4 bg-surface-container rounded-2xl hover:bg-surface-container-low transition-all font-bold text-sm"
          >
            <Chrome className="w-5 h-5" />
            Google
          </button>
        </div>
      </div>

      <div className="mt-12 text-center">
        <button 
          onClick={onSwitch}
          className="text-sm font-bold text-on-surface-variant hover:text-primary transition-colors"
        >
          {type === 'login' ? "Don't have an account? Sign Up" : "Already have an account? Sign In"}
        </button>
      </div>
    </div>
  );
};
