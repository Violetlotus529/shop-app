class CreateProductVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku,     null: false
      t.string :color,  null: false
      t.string :size,   null: false
      t.integer :stock, null: false, default: 0
      t.boolean :deleted, null: false, default: false

      t.timestamps
    end
    add_index :product_variants, :sku, unique: true
  end
end
