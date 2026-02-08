class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :restrict_with_error
  has_many :cart_items, dependent: :destroy
  scope :active, -> { where(deleted: false) }
  scope :out_of_stock, -> { where("stock <= 0") }
  def admin_out_of_stock_row
    {
      id: id,
      product_name: product&.name,
      color: color,
      size: size,
      stock: stock
    }
  end
end
