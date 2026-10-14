import React, {
  createContext,
  useState,
  useContext,
  ReactNode,
  useEffect,
  useCallback,
} from 'react';
import { Cart } from '../types';
import api from '../services/api';
import { useAuth } from './AuthContext';
import { getApiErrorMessage, normalizeCart } from '../utils/money';

interface CartContextType {
  cart: Cart | null;
  isLoading: boolean;
  refreshCart: () => Promise<void>;
  addToCart: (productId: number, quantity?: number) => Promise<void>;
  updateCartItem: (itemId: number, quantity: number) => Promise<void>;
  removeFromCart: (itemId: number) => Promise<void>;
  /** Resolves on success; rejects with an Error whose message is shopper-friendly. */
  applyPromoCode: (code: string) => Promise<void>;
  removePromoCode: () => Promise<void>;
  clearPromoNotice: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const CartProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [cart, setCart] = useState<Cart | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { isAuthenticated } = useAuth();

  const refreshCart = useCallback(async () => {
    if (!isAuthenticated) {
      return;
    }
    try {
      setIsLoading(true);
      const response = await api.get('/cart');
      setCart(normalizeCart(response.data));
    } catch (error) {
      console.error('Error fetching cart:', error);
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    if (isAuthenticated) {
      refreshCart();
    } else {
      setCart(null);
    }
  }, [isAuthenticated, refreshCart]);

  const addToCart = async (productId: number, quantity: number = 1) => {
    try {
      await api.post('/cart/items', { product_id: productId, quantity });
      await refreshCart();
    } catch (error) {
      console.error('Error adding to cart:', error);
      throw error;
    }
  };

  // Previously this was an optimistic, fire-and-forget update: line subtotals
  // and the cart total were never recalculated and server errors (e.g. stock)
  // were swallowed, so the screen could show a quantity the server rejected.
  // Now: optimistic quantity, then re-sync from the server (which also
  // recalculates any promo discount), rolling back on failure.
  const updateCartItem = async (itemId: number, quantity: number) => {
    const previous = cart;
    if (cart) {
      setCart({
        ...cart,
        items: cart.items.map(item =>
          item.id === itemId ? { ...item, quantity } : item,
        ),
      });
    }
    try {
      await api.patch(`/cart/items/${itemId}`, { quantity });
      const response = await api.get('/cart');
      setCart(normalizeCart(response.data));
    } catch (error) {
      console.error('Error updating cart item:', error);
      setCart(previous);
      throw new Error(getApiErrorMessage(error, 'Could not update quantity.'));
    }
  };

  const removeFromCart = async (itemId: number) => {
    try {
      await api.delete(`/cart/items/${itemId}`);
      await refreshCart();
    } catch (error) {
      console.error('Error removing from cart:', error);
      throw error;
    }
  };

  const applyPromoCode = async (code: string) => {
    const trimmed = code.trim();
    if (!trimmed) {
      throw new Error('Please enter a promo code.');
    }
    try {
      const response = await api.post('/cart/promo_code', { code: trimmed });
      setCart(normalizeCart(response.data));
    } catch (error) {
      throw new Error(
        getApiErrorMessage(error, "That code couldn't be applied. Please try again."),
      );
    }
  };

  const removePromoCode = async () => {
    try {
      const response = await api.delete('/cart/promo_code');
      setCart(normalizeCart(response.data));
    } catch (error) {
      throw new Error(getApiErrorMessage(error, "Couldn't remove the code. Please try again."));
    }
  };

  const clearPromoNotice = useCallback(() => {
    setCart(current => (current ? { ...current, promo_notice: null } : current));
  }, []);

  return (
    <CartContext.Provider
      value={{
        cart,
        isLoading,
        refreshCart,
        addToCart,
        updateCartItem,
        removeFromCart,
        applyPromoCode,
        removePromoCode,
        clearPromoNotice,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};
