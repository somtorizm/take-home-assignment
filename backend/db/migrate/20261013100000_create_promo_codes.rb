class CreatePromoCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :promo_codes do |t|
      t.string :code, null: false
      t.string :discount_type, null: false # "percent" | "fixed"
      t.decimal :value, precision: 10, scale: 2, null: false
      t.datetime :starts_at
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    # Codes are stored upper-cased, so a plain unique index enforces
    # case-insensitive uniqueness at the database level.
    add_index :promo_codes, :code, unique: true
  end
end
