require "test_helper"

class PromoCodeTest < ActiveSupport::TestCase
  test "normalizes code to upper case and strips whitespace" do
    promo = PromoCode.create!(code: "  spring25 ", discount_type: "percent", value: 25)
    assert_equal "SPRING25", promo.code
  end

  test "code is unique case-insensitively" do
    dup = PromoCode.new(code: "welcome10", discount_type: "fixed", value: 1)
    assert_not dup.valid?
    assert_includes dup.errors[:code], "has already been taken"
  end

  test "validates discount type and value" do
    assert_not PromoCode.new(code: "X1", discount_type: "bogo", value: 1).valid?
    assert_not PromoCode.new(code: "X2", discount_type: "fixed", value: 0).valid?
    assert_not PromoCode.new(code: "X3", discount_type: "percent", value: 101).valid?
    assert PromoCode.new(code: "X4", discount_type: "percent", value: 100).valid?
  end

  test "percent discount rounds to cents" do
    assert_equal BigDecimal("3.33"), promo_codes(:welcome10).discount_for(BigDecimal("33.33"))
  end

  test "fixed discount is capped at the subtotal" do
    assert_equal BigDecimal("5"), promo_codes(:save5).discount_for(BigDecimal("20"))
    assert_equal BigDecimal("12.99"), promo_codes(:bigsaver).discount_for(BigDecimal("12.99"))
  end

  test "redeemable! finds codes case-insensitively" do
    assert_equal promo_codes(:welcome10), PromoCode.redeemable!(" welcome10 ")
  end

  test "redeemable! explains why a code can't be used" do
    {
      "" => :blank,
      "NOPE" => :not_found,
      "expired" => :expired,
      "DISABLED" => :inactive
    }.each do |input, reason|
      error = assert_raises(PromoCode::Invalid) { PromoCode.redeemable!(input) }
      assert_equal reason, error.reason, "for #{input.inspect}"
      assert error.message.present?
    end
  end

  test "codes with a future start date are not yet redeemable" do
    promo = PromoCode.create!(code: "LATER", discount_type: "fixed", value: 1, starts_at: 1.day.from_now)
    assert_not promo.redeemable?
  end
end
