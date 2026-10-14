class Order < ApplicationRecord
  belongs_to :user
  belongs_to :promo_code, optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  # 0 is allowed: a 100% code or a fixed code that covers the whole cart.
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }

  def promo_summary
    return nil unless promo_code_snapshot
    { code: promo_code_snapshot, discount_type: promo_discount_type, value: promo_value }
  end
end
