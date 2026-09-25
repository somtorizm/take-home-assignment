class Api::OrdersController < ApplicationController
  def index
    orders = current_user.orders.order(created_at: :desc)
    render json: orders.map do |order|
      {
        id: order.id,
        total_amount: order.total_amount,
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
    end, status: :ok
  end

  def create
    cart = current_user.cart
    if cart.cart_items.empty?
      render json: { error: 'Cart is empty' }, status: :unprocessable_entity
      return
    end

    order = Order.new(
      user: current_user,
      total_amount: cart.total,
      status: 'pending'
    )

    if order.save
      cart.cart_items.each do |cart_item|
        OrderItem.create(
          order: order,
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: cart_item.product.price
        )
        # Update stock
        cart_item.product.update(stock_quantity: cart_item.product.stock_quantity - cart_item.quantity)
      end

      cart.cart_items.destroy_all

      render json: {
        id: order.id,
        total_amount: order.total_amount,
        status: order.status,
        created_at: order.created_at
      }, status: :created
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end
end

