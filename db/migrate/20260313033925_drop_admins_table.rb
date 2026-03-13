class DropAdminsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :admins
  end
end