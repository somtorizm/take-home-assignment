require "test_helper"

class PromoCodesFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: @user.id)}" }
    # Make the cart a round $50 to keep the maths readable.
    products(:one).update!(price: 25, stock_quantity: 10)
    cart_items(:one).update!(quantity: 2)
  end

  def json = JSON.parse(response.body)

  test "requires authentication" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }
    assert_response :unauthorized
  end

  test "apply a percent code and see the discount on the cart" do
    post "/api/cart/promo_code", params: { code: "welcome10" }, headers: @headers
    assert_response :ok
    assert_equal "WELCOME10", json["promo_code"]["code"]
    assert_equal "50.0", json["subtotal"]
    assert_equal "5.0", json["discount"]
    assert_equal "45.0", json["total"]

    get "/api/cart", headers: @headers
    assert_equal "WELCOME10", json["promo_code"]["code"]
  end

  test "invalid codes return 422 with a reason and message" do
    { "NOPE" => "not_found", "EXPIRED" => "expired", "DISABLED" => "inactive", "" => "blank" }.each do |code, reason|
      post "/api/cart/promo_code", params: { code: code }, headers: @headers
      assert_response :unprocessable_entity
      assert_equal reason, json["reason"]
      assert json["error"].present?
    end
    assert_nil @user.cart.reload.promo_code
  end

  test "cannot apply a code to an empty cart" do
    @user.cart.cart_items.destroy_all
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    assert_response :unprocessable_entity
    assert_equal "empty_cart", json["reason"]
  end

  test "remove a code" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    delete "/api/cart/promo_code", headers: @headers
    assert_response :ok
    assert_nil json["promo_code"]
    assert_equal "50.0", json["total"]
  end

  test "cart drops a code that expired after it was applied and explains why" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    promo_codes(:save5).update!(expires_at: 1.minute.ago)
    get "/api/cart", headers: @headers
    assert_nil json["promo_code"]
    assert_match "expired", json["promo_notice"]
  end

  test "checkout with a code stores the price breakdown and snapshot" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    assert_difference -> { Order.count }, 1 do
      post "/api/orders", params: { promo_code: "SAVE5" }, headers: @headers
    end
    assert_response :created
    assert_equal "50.0", json["subtotal_amount"]
    assert_equal "5.0", json["discount_amount"]
    assert_equal "45.0", json["total_amount"]
    assert_equal "SAVE5", json["promo_code"]["code"]

    order = Order.find(json["id"])
    assert_equal "SAVE5", order.promo_code_snapshot
    assert_nil @user.cart.reload.promo_code, "code is consumed by the order"
    assert_empty @user.cart.cart_items

    # History keeps showing what was paid even if the code is later changed.
    promo_codes(:save5).update!(value: 20, active: false)
    get "/api/orders", headers: @headers
    latest = json.first
    assert_equal "45.0", latest["total_amount"]
    assert_equal "5.0", latest["discount_amount"]
    assert_equal "5.0", latest["promo_code"]["value"]
  end

  test "checkout revalidates the code and does not place the order if it became invalid" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    promo_codes(:save5).update!(active: false)
    assert_no_difference -> { Order.count } do
      post "/api/orders", params: { promo_code: "SAVE5" }, headers: @headers
    end
    assert_response :unprocessable_entity
    assert_equal "promo_invalid", json["reason"]
    assert_nil @user.cart.reload.promo_code
  end

  test "checkout rejects a mismatch between the app's code and the cart's code" do
    post "/api/cart/promo_code", params: { code: "SAVE5" }, headers: @headers
    assert_no_difference -> { Order.count } do
      post "/api/orders", params: { promo_code: "WELCOME10" }, headers: @headers
    end
    assert_response :conflict
    assert_equal "promo_mismatch", json["reason"]
  end

  test "fixed discount larger than the cart produces a $0 order" do
    post "/api/cart/promo_code", params: { code: "BIGSAVER" }, headers: @headers
    post "/api/orders", params: { promo_code: "BIGSAVER" }, headers: @headers
    assert_response :created
    assert_equal "50.0", json["discount_amount"]
    assert_equal "0.0", json["total_amount"]
  end

  test "checkout without a code still works and history includes items" do
    post "/api/orders", headers: @headers
    assert_response :created
    assert_equal "0.0", json["discount_amount"]
    assert_nil json["promo_code"]

    get "/api/orders", headers: @headers
    assert_response :ok
    assert json.first["items"].any?
  end

  test "checkout fails atomically when stock ran out" do
    products(:one).update_column(:stock_quantity, 1)
    assert_no_difference -> { Order.count } do
      post "/api/orders", headers: @headers
    end
    assert_response :unprocessable_entity
    assert_equal 2, @user.cart.cart_items.first.quantity
  end
end
