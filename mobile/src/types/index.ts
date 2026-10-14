export type DiscountType = 'percent' | 'fixed';

export interface User {
  id: number;
  email: string;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  image_url: string;
  stock_quantity: number;
}

export interface CartItem {
  id: number;
  product: Product;
  quantity: number;
  subtotal: number;
}

export interface Cart {
  id: number;
  items: CartItem[];
  subtotal: number;
  discount: number;
  promo_code: AppliedPromoCode | null;
  promo_notice: string | null;
  total: number;
}

export interface OrderItem {
  product_name: string;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface Order {
  id: number;
  subtotal_amount: number;
  discount_amount: number;
  promo_code: OrderPromoCode | null;
  total_amount: number;
  status: string;
  created_at: string;
  items: OrderItem[];
}

export interface OrderPromoCode {
  code: string;
  discount_type: DiscountType;
  value: number;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface AppliedPromoCode {
  code: string;
  discount_type: DiscountType;
  value: number;
  description: string;
}

