class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validate :product_available

  def subtotal
    product.price * quantity
  end

  private

  def product_available
    if quantity && product && quantity > product.stock_quantity
      errors.add(:quantity, "exceeds available stock")
    end
  end
end
