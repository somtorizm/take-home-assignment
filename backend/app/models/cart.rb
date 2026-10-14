class Cart < ApplicationRecord
  belongs_to :user
  belongs_to :promo_code, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  # Money is summed as BigDecimal (not Float) to avoid rounding drift.
  def subtotal
    cart_items.includes(:product).sum(BigDecimal('0')) { |item| item.product.price * item.quantity }
  end

  def discount
    promo_code ? promo_code.discount_for(subtotal) : BigDecimal('0')
  end

  def total
    subtotal - discount
  end

  def apply_promo_code!(raw)
    promo = PromoCode.redeemable!(raw)
    update!(promo_code: promo)
    promo
  end

  def remove_promo_code!
    update!(promo_code: nil)
  end

  # If the applied code stopped being valid (expired / switched off) since the
  # shopper applied it, drop it and return the reason so the UI can explain.
  def drop_stale_promo_code!
    return nil unless promo_code
    promo_code.ensure_redeemable!
    nil
  rescue PromoCode::Invalid => e
    update!(promo_code: nil)
    e.message
  end
end
