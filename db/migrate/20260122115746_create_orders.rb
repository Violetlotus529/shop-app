class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: true, foreign_key: true

      t.integer :status, null: false, default: 0
      t.integer :total_cents, null: false, default: 0

      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.datetime :paid_at

      # snapshot (purchase-time shipping info)
      t.string :customer_name
      t.string :customer_email
      t.string :postal_code
      t.string :prefecture
      t.string :city
      t.string :address_line1
      t.string :address_line2

      t.timestamps
    end

    add_index :orders, :stripe_checkout_session_id
    add_index :orders, :stripe_payment_intent_id
  end
end
