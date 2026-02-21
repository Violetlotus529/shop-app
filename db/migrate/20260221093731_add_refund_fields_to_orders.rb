class AddRefundFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :refunded_at, :datetime
    add_column :orders, :stripe_refund_id, :string
    add_index  :orders, :string_refund_id, unique: true
  end
end
