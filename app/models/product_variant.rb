class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :restrict_with_error
  has_many :cart_items, dependent: :destroy
  scope :active, -> { where(deleted: false) }
end
