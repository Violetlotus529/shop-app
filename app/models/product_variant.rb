class ProductVariant < ApplicationRecord
  belongs_to :product

  scope :active, -> { where(deleted: false) }
end
