import AsyncStorage from '@react-native-async-storage/async-storage';
import api from './api';
import { AuthResponse } from '../types';

export const login = async (email: string, password: string): Promise<AuthResponse> => {
  const response = await api.post('/auth/login', { email, password });
  const { token, user } = response.data;
  await AsyncStorage.setItem('token', token);
  return { token, user };
};

export const signup = async (email: string, password: string): Promise<AuthResponse> => {
  const response = await api.post('/auth/signup', {
    user: { email, password, password_confirmation: password },
  });
  const { token, user } = response.data;
  await AsyncStorage.setItem('token', token);
  return { token, user };
};

export const logout = async (): Promise<void> => {
  await AsyncStorage.removeItem('token');
};

export const getStoredToken = async (): Promise<string | null> => {
  return await AsyncStorage.getItem('token');
};

