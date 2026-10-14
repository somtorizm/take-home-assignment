class PromoCode < ApplicationRecord
  DISCOUNT_TYPES = %w[percent fixed].freeze

  # Raised when a shopper tries a code that can't be used right now.
  class Invalid < StandardError
    attr_reader :reason
    def initialize(reason, message)
      @reason = reason
      super(message)
    end
  end

  has_many :carts, dependent: :nullify
  has_many :orders, dependent: :restrict_with_error

  before_validation :normalize_code

  validates :code, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[A-Z0-9_-]+\z/, message: 'may only contain letters, numbers, - and _' },
                   length: { maximum: 32 }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES }
  validates :value, numericality: { greater_than: 0 }
  validates :value, numericality: { less_than_or_equal_to: 100 }, if: :percent?
  validate :expiry_after_start

  def self.normalize(raw)
    raw.to_s.strip.upcase
  end

  def self.find_by_code(raw)
    find_by(code: normalize(raw))
  end

  # Looks up a code and checks it's usable. Raises PromoCode::Invalid with a
  # shopper-friendly message otherwise.
  def self.redeemable!(raw, now: Time.current)
    normalized = normalize(raw)
    raise Invalid.new(:blank, 'Please enter a promo code.') if normalized.blank?

    promo = find_by(code: normalized)
    raise Invalid.new(:not_found, "We couldn't find the code \"#{normalized}\". Check the spelling and try again.") unless promo

    promo.ensure_redeemable!(now: now)
    promo
  end

  def percent?
    discount_type == 'percent'
  end

  def fixed?
    discount_type == 'fixed'
  end

  def ensure_redeemable!(now: Time.current)
    raise Invalid.new(:inactive, "The code \"#{code}\" is no longer available.") unless active?
    raise Invalid.new(:not_started, "The code \"#{code}\" isn't active yet.") if starts_at && now < starts_at
    raise Invalid.new(:expired, "The code \"#{code}\" expired on #{expires_at.to_date.strftime('%b %-d, %Y')}.") if expires_at && now >= expires_at
    true
  end

  def redeemable?(now: Time.current)
    ensure_redeemable!(now: now)
  rescue Invalid
    false
  end

  # Discount for a given subtotal, in BigDecimal dollars, rounded to cents and
  # never more than the subtotal (so totals can't go negative).
  def discount_for(subtotal)
    subtotal = BigDecimal(subtotal.to_s)
    raw = percent? ? subtotal * value / 100 : value
    [raw.round(2, BigDecimal::ROUND_HALF_UP), subtotal].min
  end

  def description
    percent? ? "#{value.to_i == value ? value.to_i : value}% off" : "$#{'%.2f' % value} off"
  end

  def as_summary_json
    { code: code, discount_type: discount_type, value: value, description: description }
  end

  private

  def normalize_code
    self.code = self.class.normalize(code) if code
  end

  def expiry_after_start
    return unless starts_at && expires_at
    errors.add(:expires_at, 'must be after the start date') if expires_at <= starts_at
  end
end
