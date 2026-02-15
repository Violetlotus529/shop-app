class AddCategoryToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :category, :string, null: false, default: "tops"
    add_index  :products, :category
  end
end
