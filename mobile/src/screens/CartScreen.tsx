import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { CartItem } from '../components/CartItem';
import { Button } from '../components/Button';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { PromoCodeInput } from '../components/PromoCodeInput';
import { formatMoney, getApiErrorMessage } from '../utils/money';

export const CartScreen: React.FC<{ navigation: any }> = ({ navigation }) => {
  const {
    cart,
    isLoading,
    refreshCart,
    updateCartItem,
    removeFromCart,
    applyPromoCode,
    removePromoCode,
    clearPromoNotice,
  } = useCart();
  const { isAuthenticated } = useAuth();
  const [checkoutLoading, setCheckoutLoading] = React.useState(false);

  useEffect(() => {
    if (isAuthenticated) {
      refreshCart();
    }
  }, [isAuthenticated, refreshCart]);

  // The server drops a code that expired / was switched off after it was
  // applied; tell the shopper instead of silently changing their total.
  useEffect(() => {
    if (cart?.promo_notice) {
      Alert.alert('Promo code removed', cart.promo_notice);
      clearPromoNotice();
    }
  }, [cart?.promo_notice, clearPromoNotice]);

  const handleUpdateQuantity = (itemId: number, quantity: number) => {
    updateCartItem(itemId, quantity).catch((e: Error) =>
      Alert.alert("Couldn't update quantity", e.message),
    );
  };

  const handleCheckout = async () => {
    if (!cart || cart.items.length === 0) {
      Alert.alert('Empty Cart', 'Your cart is empty');
      return;
    }

    try {
      setCheckoutLoading(true);
      // Send the code the shopper saw so the server can refuse to charge a
      // different price than what's on screen.
      await api.post('/orders', { promo_code: cart.promo_code?.code ?? null });
      Alert.alert('Success', 'Order placed successfully!', [
        {
          text: 'OK',
          onPress: () => {
            refreshCart();
            navigation.navigate('OrderHistory');
          },
        },
      ]);
    } catch (error: any) {
      const reason = error?.response?.data?.reason;
      if (reason === 'promo_invalid' || reason === 'promo_mismatch') {
        // Totals changed: reload so the shopper sees the new price before retrying.
        await refreshCart();
        Alert.alert('Please review your total', getApiErrorMessage(error, 'Your total changed.'));
      } else {
        Alert.alert('Error', getApiErrorMessage(error, 'Failed to place order'));
      }
    } finally {
      setCheckoutLoading(false);
    }
  };

  if (!isAuthenticated) {
    return (
      <View style={styles.center}>
        <Text style={styles.message}>Please login to view your cart</Text>
        <Button title="Login" onPress={() => navigation.navigate('Login')} />
      </View>
    );
  }

  // Only block the whole screen on the first load; later refreshes keep the
  // cart (and the promo field) on screen.
  if (isLoading && !cart) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  if (!cart || cart.items.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={styles.emptyText}>Your cart is empty</Text>
        <Button
          title="Browse Products"
          onPress={() => navigation.navigate('ProductList')}
          variant="secondary"
        />
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 64 : 0}
    >
      <FlatList
        data={cart.items}
        renderItem={({ item }) => (
          <CartItem
            item={item}
            onUpdateQuantity={handleUpdateQuantity}
            onRemove={removeFromCart}
          />
        )}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.list}
      />
      <View style={styles.footer}>
        <PromoCodeInput
          appliedCode={cart.promo_code}
          onApply={applyPromoCode}
          onRemove={removePromoCode}
          disabled={checkoutLoading}
        />
        {cart.promo_code ? (
          <>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Subtotal</Text>
              <Text style={styles.summaryValue} testID="cart-subtotal">
                {formatMoney(cart.subtotal)}
              </Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.discountLabel}>Discount ({cart.promo_code.code})</Text>
              <Text style={styles.discountValue} testID="cart-discount">
                -{formatMoney(cart.discount)}
              </Text>
            </View>
          </>
        ) : null}
        <View style={styles.totalContainer}>
          <Text style={styles.totalLabel}>Total:</Text>
          <Text style={styles.totalAmount} testID="cart-total">
            {formatMoney(cart.total)}
          </Text>
        </View>
        <Button
          title="Checkout"
          onPress={handleCheckout}
          loading={checkoutLoading}
        />
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  list: {
    padding: 16,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  summaryLabel: { fontSize: 15, color: '#666' },
  summaryValue: { fontSize: 15, color: '#333' },
  discountLabel: { fontSize: 15, color: '#1E7B3A' },
  discountValue: { fontSize: 15, color: '#1E7B3A', fontWeight: '600' },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  message: {
    fontSize: 16,
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
  },
  emptyText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 16,
  },
  footer: {
    backgroundColor: '#fff',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 5,
  },
  totalContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  totalLabel: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
  },
  totalAmount: {
    fontSize: 24,
    fontWeight: '700',
    color: '#007AFF',
  },
});

