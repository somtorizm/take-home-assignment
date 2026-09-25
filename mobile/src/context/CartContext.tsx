import React, { createContext, useState, useContext, ReactNode, useEffect } from 'react';
import { Cart, CartItem } from '../types';
import api from '../services/api';
import { useAuth } from './AuthContext';

interface CartContextType {
  cart: Cart | null;
  isLoading: boolean;
  refreshCart: () => Promise<void>;
  addToCart: (productId: number, quantity?: number) => Promise<void>;
  updateCartItem: (itemId: number, quantity: number) => Promise<void>;
  removeFromCart: (itemId: number) => Promise<void>;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const CartProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [cart, setCart] = useState<Cart | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { isAuthenticated } = useAuth();

  useEffect(() => {
    if (isAuthenticated) {
      refreshCart();
    }
  }, [isAuthenticated]);

  const refreshCart = async () => {
    if (!isAuthenticated) return;
    try {
      setIsLoading(true);
      const response = await api.get('/cart');
      // Convert price strings to numbers in cart items
      const cartData = response.data;
      if (cartData && cartData.items) {
        cartData.items = cartData.items.map((item: any) => ({
          ...item,
          product: {
            ...item.product,
            price: typeof item.product?.price === 'string' ? parseFloat(item.product.price) : item.product?.price,
          },
          subtotal: typeof item.subtotal === 'string' ? parseFloat(item.subtotal) : item.subtotal,
        }));
        cartData.total = typeof cartData.total === 'string' ? parseFloat(cartData.total) : cartData.total;
      }
      setCart(cartData);
    } catch (error) {
      console.error('Error fetching cart:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const addToCart = async (productId: number, quantity: number = 1) => {
    try {
      await api.post('/cart/items', { product_id: productId, quantity });
      await refreshCart();
    } catch (error) {
      console.error('Error adding to cart:', error);
      throw error;
    }
  };

  const updateCartItem = async (itemId: number, quantity: number) => {
    // Optimistic update for a snappier cart
    if (cart) {
      setCart({
        ...cart,
        items: cart.items.map(item =>
          item.id === itemId ? { ...item, quantity } : item
        ),
      });
    }
    api.patch(`/cart/items/${itemId}`, { quantity }).catch(error => {
      console.error('Error updating cart item:', error);
    });
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

  return (
    <CartContext.Provider
      value={{
        cart,
        isLoading,
        refreshCart,
        addToCart,
        updateCartItem,
        removeFromCart,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => {
  const context = useContext(CartContext);
  if (context === undefined) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};

