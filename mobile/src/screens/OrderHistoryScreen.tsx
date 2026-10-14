import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
} from 'react-native';
import { Order } from '../types';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { formatMoney, normalizeOrder } from '../utils/money';

export const OrderHistoryScreen: React.FC<{ navigation: any }> = ({ navigation }) => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const { isAuthenticated } = useAuth();

  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const response = await api.get('/orders');
        setOrders(response.data.map(normalizeOrder));
        setError(null);
      } catch (e) {
        console.error('Error fetching orders:', e);
        setError("Couldn't load your orders. Please try again later.");
      } finally {
        setLoading(false);
      }
    };
    if (isAuthenticated) {
      fetchOrders();
    }
  }, [isAuthenticated]);

  if (!isAuthenticated) {
    return (
      <View style={styles.center}>
        <Text style={styles.message}>Please login to view your orders</Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.buttonText}>Login</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    );
  }

  const renderOrder = ({ item }: { item: Order }) => (
    <View style={styles.orderCard}>
      <View style={styles.orderHeader}>
        <Text style={styles.orderId}>Order #{item.id}</Text>
        <Text style={[styles.status, getStatusColor(item.status)]}>{item.status}</Text>
      </View>
      <Text style={styles.date}>
        {new Date(item.created_at).toLocaleDateString()}
      </Text>
      <View style={styles.itemsContainer}>
        {item.items.map((orderItem, index) => (
          <View key={index} style={styles.orderItem}>
            <Text style={styles.itemName}>{orderItem.product_name}</Text>
            <Text style={styles.itemDetails}>
              {orderItem.quantity} x ${orderItem.price.toFixed(2)} = $
              {orderItem.subtotal.toFixed(2)}
            </Text>
          </View>
        ))}
      </View>
      {item.discount_amount > 0 ? (
        <View style={styles.breakdown}>
          <View style={styles.breakdownRow}>
            <Text style={styles.breakdownLabel}>Subtotal</Text>
            <Text style={styles.breakdownValue}>{formatMoney(item.subtotal_amount)}</Text>
          </View>
          <View style={styles.breakdownRow}>
            <Text style={styles.discountLabel}>
              Discount{item.promo_code ? ` (${item.promo_code.code})` : ''}
            </Text>
            <Text style={styles.discountLabel}>-{formatMoney(item.discount_amount)}</Text>
          </View>
        </View>
      ) : null}
      <View style={styles.totalContainer}>
        <Text style={styles.totalLabel}>{item.discount_amount > 0 ? 'Paid:' : 'Total:'}</Text>
        <Text style={styles.totalAmount}>{formatMoney(item.total_amount)}</Text>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
      {orders.length === 0 ? (
        <View style={styles.center}>
          <Text style={styles.emptyText}>No orders yet</Text>
          <TouchableOpacity
            style={styles.button}
            onPress={() => navigation.navigate('ProductList')}
          >
            <Text style={styles.buttonText}>Browse Products</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
          data={orders}
          renderItem={renderOrder}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.list}
        />
      )}
    </View>
  );
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'completed':
      return { color: '#34C759' };
    case 'pending':
      return { color: '#FF9500' };
    case 'cancelled':
      return { color: '#FF3B30' };
    default:
      return { color: '#666' };
  }
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  list: {
    padding: 16,
  },
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
  button: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  orderId: {
    fontSize: 18,
    fontWeight: '700',
    color: '#333',
  },
  status: {
    fontSize: 14,
    fontWeight: '600',
    textTransform: 'capitalize',
  },
  date: {
    fontSize: 14,
    color: '#666',
    marginBottom: 12,
  },
  breakdown: {
    marginTop: 4,
  },
  breakdownRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  breakdownLabel: { fontSize: 14, color: '#666' },
  breakdownValue: { fontSize: 14, color: '#333' },
  discountLabel: { fontSize: 14, color: '#1E7B3A', fontWeight: '600' },
  errorText: { color: '#FF3B30', textAlign: 'center', padding: 12 },
  itemsContainer: {
    marginBottom: 12,
  },
  orderItem: {
    marginBottom: 8,
  },
  itemName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 2,
  },
  itemDetails: {
    fontSize: 14,
    color: '#666',
  },
  totalContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  totalLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  totalAmount: {
    fontSize: 20,
    fontWeight: '700',
    color: '#007AFF',
  },
});

