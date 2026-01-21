class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string  :name,        null: false
      t.text    :description
      t.integer :price_cents, null: false
      t.boolean :published,   null: false, default: false
      t.boolean :deleted,     null: false, default: false

      t.timestamps
    end
  end
end
