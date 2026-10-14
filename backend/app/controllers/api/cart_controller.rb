class Api::CartController < ApplicationController
  def show
    cart = current_user.cart
    notice = cart.drop_stale_promo_code!
    render json: serialize_cart(cart, promo_notice: notice), status: :ok
  end

  def add_item
    cart = current_user.cart
    product = Product.find(params[:product_id])
    quantity = params[:quantity] || 1

    cart_item = cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = cart_item.quantity.to_i + quantity.to_i

    if cart_item.save
      render json: { message: 'Item added to cart', cart_item: cart_item }, status: :ok
    else
      render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  def update_item
    cart_item = current_user.cart.cart_items.find(params[:id])
    if cart_item.update(quantity: params[:quantity])
      render json: { message: 'Cart item updated', cart_item: cart_item }, status: :ok
    else
      render json: { errors: cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Cart item not found' }, status: :not_found
  end

  def remove_item
    cart_item = current_user.cart.cart_items.find(params[:id])
    cart_item.destroy
    render json: { message: 'Item removed from cart' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Cart item not found' }, status: :not_found
  end

  # POST /api/cart/promo_code  { code: "WELCOME10" }
  # Applying a new code replaces any existing one (one code per order).
  def apply_promo_code
    cart = current_user.cart
    if cart.cart_items.empty?
      render json: { error: 'Add something to your cart before applying a promo code.', reason: 'empty_cart' },
             status: :unprocessable_entity
      return
    end
    cart.apply_promo_code!(params[:code])
    render json: serialize_cart(cart.reload), status: :ok
  rescue PromoCode::Invalid => e
    render json: { error: e.message, reason: e.reason }, status: :unprocessable_entity
  end

  # DELETE /api/cart/promo_code
  def remove_promo_code
    cart = current_user.cart
    cart.remove_promo_code!
    render json: serialize_cart(cart.reload), status: :ok
  end

  private

  def serialize_cart(cart, promo_notice: nil)
    items = cart.cart_items.includes(:product)
    {
      id: cart.id,
      items: items.map do |item|
        {
          id: item.id,
          product: {
            id: item.product.id,
            name: item.product.name,
            description: item.product.description,
            price: item.product.price,
            image_url: item.product.image_url,
            stock_quantity: item.product.stock_quantity
          },
          quantity: item.quantity,
          subtotal: item.subtotal
        }
      end,
      subtotal: cart.subtotal,
      discount: cart.discount,
      total: cart.total,
      promo_code: cart.promo_code&.as_summary_json,
      promo_notice: promo_notice
    }
  end
end
