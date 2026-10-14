class Api::OrdersController < ApplicationController
  def index
    orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
    # NOTE: the original `render json: orders.map do ... end` bound the block to
    # `render`, not `map`, so the serializer below never ran.
    payload = orders.map { |order| serialize_order(order) }
    render json: payload, status: :ok
  end

  def create
    cart = current_user.cart
    if cart.cart_items.empty?
      render json: { error: 'Cart is empty' }, status: :unprocessable_entity
      return
    end

    promo = cart.promo_code

    # The app sends the code it showed the shopper. If that doesn't match the
    # cart (e.g. changed on another device), don't charge a price they didn't see.
    if params.key?(:promo_code)
      expected = PromoCode.normalize(params[:promo_code]).presence
      if expected != promo&.code
        render json: {
          error: 'Your promo code changed since you last viewed your cart. Please review your total and try again.',
          reason: 'promo_mismatch'
        }, status: :conflict
        return
      end
    end

    # Revalidate at checkout: a code may have expired or been switched off
    # since it was applied. Remove it and ask the shopper to review.
    if promo && !promo.redeemable?
      notice = cart.drop_stale_promo_code!
      render json: {
        error: "#{notice} It has been removed from your cart, so your order wasn't placed. Please review your new total.",
        reason: 'promo_invalid'
      }, status: :unprocessable_entity
      return
    end

    order = nil
    ActiveRecord::Base.transaction do
      cart.lock!
      subtotal = cart.subtotal
      discount = promo ? promo.discount_for(subtotal) : BigDecimal('0')
      order = Order.create!(
        user: current_user,
        subtotal_amount: subtotal,
        discount_amount: discount,
        total_amount: subtotal - discount,
        promo_code: promo,
        promo_code_snapshot: promo&.code,
        promo_discount_type: promo&.discount_type,
        promo_value: promo&.value,
        status: 'pending'
      )

      cart.cart_items.includes(:product).each do |cart_item|
        product = cart_item.product
        product.lock!
        if product.stock_quantity < cart_item.quantity
          raise ActiveRecord::RecordInvalid.new(cart_item.tap { |ci| ci.errors.add(:base, "Not enough stock for #{product.name}") })
        end
        OrderItem.create!(order: order, product: product, quantity: cart_item.quantity, price: product.price)
        product.update!(stock_quantity: product.stock_quantity - cart_item.quantity)
      end

      cart.cart_items.destroy_all
      cart.update!(promo_code: nil)
    end

    render json: serialize_order(order.reload), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def serialize_order(order)
    {
      id: order.id,
      subtotal_amount: order.subtotal_amount || order.total_amount,
      discount_amount: order.discount_amount,
      total_amount: order.total_amount,
      promo_code: order.promo_summary,
      status: order.status,
      created_at: order.created_at,
      items: order.order_items.map do |item|
        {
          product_name: item.product.name,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal
        }
      end
    }
  end
end
