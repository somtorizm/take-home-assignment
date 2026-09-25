import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {API_URL} from '@env';

// API URL from environment variable
// Configure in .env file
// For iOS Simulator/Android Emulator: use http://localhost:3000/api
// For physical devices: use your computer's local IP address (e.g., http://192.168.100.97:3000/api)
const API_BASE_URL = API_URL || 'http://localhost:3000/api';

console.log('=== API Service Initializing ===');
console.log('API_URL from .env:', API_URL);
console.log('Final API_BASE_URL:', API_BASE_URL);
console.log('=== API Service Initialized ===');

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Log the base URL when API is created
console.log('Axios instance created with baseURL:', api.defaults.baseURL);

// Add token to requests
api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Log the full URL being requested
    const fullUrl = `${config.baseURL || API_BASE_URL}${config.url}`;
    console.log('🌐 API Request:', config.method?.toUpperCase(), fullUrl);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Handle token expiration
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      await AsyncStorage.removeItem('token');
    }
    return Promise.reject(error);
  }
);

export default api;

