class AddPhoneNumberToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :phone_number, :string
  end
end
