class AddDiscountFieldsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :subtotal_amount, :decimal, precision: 10, scale: 2
    add_column :orders, :discount_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_reference :orders, :promo_code, foreign_key: true, null: true
    # Snapshot of the code as applied, so history stays correct even if the
    # promo is later edited or disabled.
    add_column :orders, :promo_code_snapshot, :string
    add_column :orders, :promo_discount_type, :string
    add_column :orders, :promo_value, :decimal, precision: 10, scale: 2

    reversible do |dir|
      dir.up { execute 'UPDATE orders SET subtotal_amount = total_amount WHERE subtotal_amount IS NULL' }
    end
  end
end
