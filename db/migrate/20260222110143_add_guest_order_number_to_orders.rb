class AddGuestOrderNumberToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :guest_order_number, :string
    add_index :orders, :guest_order_number, unique: true
  end
end
