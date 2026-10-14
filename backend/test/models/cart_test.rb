require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @cart = carts(:one) # 1 x $9.99
  end

  test "totals without a promo" do
    assert_equal BigDecimal("9.99"), @cart.subtotal
    assert_equal 0, @cart.discount
    assert_equal BigDecimal("9.99"), @cart.total
  end

  test "applying a code computes discount and total" do
    @cart.apply_promo_code!("save5")
    assert_equal BigDecimal("5"), @cart.discount
    assert_equal BigDecimal("4.99"), @cart.total
  end

  test "applying a second code replaces the first (one code per order)" do
    @cart.apply_promo_code!("SAVE5")
    @cart.apply_promo_code!("WELCOME10")
    assert_equal "WELCOME10", @cart.reload.promo_code.code
  end

  test "total never goes below zero" do
    @cart.apply_promo_code!("BIGSAVER")
    assert_equal 0, @cart.total
  end

  test "drop_stale_promo_code! removes a code that was switched off" do
    @cart.apply_promo_code!("SAVE5")
    promo_codes(:save5).update!(active: false)
    assert_match "no longer available", @cart.reload.drop_stale_promo_code!
    assert_nil @cart.reload.promo_code
  end
end
