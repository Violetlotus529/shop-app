class Product < ApplicationRecord
  has_many :product_variants, dependent: :destroy
  has_one_attached :main_image

  validates :name,        presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active,    -> { where(deleted: false) }
  scope :published, -> { where(published: true, deleted: false) }
  scope :deleted_only, -> { where(deleted: true) }
  scope :search_q, ->(q) {
    return all if q.blank?
    s = "%#{ActiveRecord::Base.sanitize_sql_like(q.to_s)}%"
    where("name LIKE :s", s: s)
  }

  scope :sorted, ->(sort) {
    case sort
    when "deleted_at_asc" then order(updated_at: :asc)
    else                       order(updated_at: :desc)
    end
  }

  def main_image_url_or_nil
    return nil unless main_image.attached?
    main_image
  end
end
