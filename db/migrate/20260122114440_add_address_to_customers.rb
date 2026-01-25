class AddAddressToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :name, :string
    add_column :customers, :postal_code, :string
    add_column :customers, :prefecture, :string
    add_column :customers, :city, :string
    add_column :customers, :address_line1, :string
    add_column :customers, :address_line2, :string
  end
end