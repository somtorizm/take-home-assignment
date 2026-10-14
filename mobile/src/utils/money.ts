import { Cart, Order } from '../types';

export const toNumber = (value: unknown): number => {
  if (typeof value === 'number') {
    return value;
  }
  const parsed = parseFloat(String(value ?? ''));
  return Number.isFinite(parsed) ? parsed : 0;
};

export const formatMoney = (value: number): string => `$${value.toFixed(2)}`;

export const getApiErrorMessage = (error: any, fallback: string): string => {
  const data = error?.response?.data;
  if (typeof data?.error === 'string' && data.error) {
    return data.error;
  }
  if (Array.isArray(data?.errors) && data.errors.length) {
    return data.errors.join('\n');
  }
  if (!error?.response) {
    return "Can't reach the server. Check your connection and try again.";
  }
  return fallback;
};
// Turns the raw /cart response into a clean Cart (money as numbers, safe defaults).
export const normalizeCart = (data: any): Cart => {
  const items = (data?.items ?? []).map((item: any) => ({
    ...item,
    product: { ...item.product, price: toNumber(item.product?.price) },
    subtotal: toNumber(item.subtotal),
  }));
  const total = toNumber(data?.total);
  return {
    id: data?.id,
    items,
    subtotal: data?.subtotal !== undefined ? toNumber(data.subtotal) : total,
    discount: toNumber(data?.discount),
    total,
    promo_code: data?.promo_code
      ? { ...data.promo_code, value: toNumber(data.promo_code.value) }
      : null,
    promo_notice: data?.promo_notice ?? null,
  };
};

// Turns a raw order into a clean Order. Old orders without a subtotal fall back to the total.
export const normalizeOrder = (order: any): Order => {
  const total = toNumber(order.total_amount);
  return {
    ...order,
    total_amount: total,
    subtotal_amount:
      order.subtotal_amount !== undefined && order.subtotal_amount !== null
        ? toNumber(order.subtotal_amount)
        : total,
    discount_amount: toNumber(order.discount_amount),
    promo_code: order.promo_code
      ? { ...order.promo_code, value: toNumber(order.promo_code.value) }
      : null,
    items: (order.items ?? []).map((item: any) => ({
      ...item,
      price: toNumber(item.price),
      subtotal: toNumber(item.subtotal),
    })),
  };
};
