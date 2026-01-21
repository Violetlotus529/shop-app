class Product < ApplicationRecord
  has_many :product_variants, dependent: :destroy
  # 必須バリデーション
  validates :name,        presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  # 論理削除されていないもの
  scope :active,    -> { where(deleted: false) }
  scope :published, -> { where(published: true, deleted: false) }
end
