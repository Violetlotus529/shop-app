class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :order_items, dependent: :destroy

  enum status: {
    pending: 0,
    paid: 1,
    processing: 2,
    shipped: 3,
    completed: 4,
    canceled: 5,
    failed: 6
  }
end
