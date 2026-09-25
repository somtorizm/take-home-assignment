import React, { createContext, useState, useEffect, useContext, ReactNode } from 'react';
import { User } from '../types';
import { getStoredToken, logout as authLogout } from '../services/auth';
import api from '../services/api';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const token = await getStoredToken();
      if (token) {
        // Verify token by making a request
        try {
          await api.get('/products');
          // If successful, token is valid
          // For now, we'll set a placeholder user
          // In production, you'd decode the JWT or call a user endpoint
          setUser({ id: 1, email: 'user@example.com' });
        } catch (error) {
          // Token invalid, clear it
          await authLogout();
        }
      }
    } catch (error) {
      await authLogout();
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string) => {
    const { login: authLogin } = await import('../services/auth');
    const { user } = await authLogin(email, password);
    setUser(user);
  };

  const signup = async (email: string, password: string) => {
    const { signup: authSignup } = await import('../services/auth');
    const { user } = await authSignup(email, password);
    setUser(user);
  };

  const logout = async () => {
    await authLogout();
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        signup,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

