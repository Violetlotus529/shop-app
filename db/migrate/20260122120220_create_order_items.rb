class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true

      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :subtotal_cents, null: false

      t.timestamps
    end
  end
end
