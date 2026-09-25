class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total
    cart_items.reduce(0.0) { |sum, item| sum + item.product.price.to_f * item.quantity }
  end
end
