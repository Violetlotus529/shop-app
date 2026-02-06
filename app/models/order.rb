class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :order_items, dependent: :destroy

  validates :postal_code,
    presence: true,
    format: { with: /\A\d{3}-?\d{4}\z/ }

  enum status: {
    pending: 0,
    paid: 1,
    processing: 2,
    shipped: 3,
    completed: 4,
    canceled: 5,
    failed: 6
  }

  scope :search_q, ->(q) {
    return all if q.blank?

    escaped = ActiveRecord::Base.sanitize_sql_like(q.to_s)
    s = "%#{escaped}%"

    where("customer_name LIKE :s OR customer_email LIKE :s OR CAST(id AS TEXT) LIKE :s", s: s)
  }

  scope :status_eq, ->(st) {
    return all if st.blank?
    return none unless statuses.key?(st)
    where(status: statuses[st])
  }

  scope :created_from, ->(from) {
    return all if from.blank?
    where("created_at >= ?", Time.zone.parse(from).beginning_of_day)
  }

  scope :created_to, ->(to) {
    return all if to.blank?
    where("created_at <= ?", Time.zone.parse(to).end_of_day)
  }

  scope :sorted, ->(sort) {
    case sort
    when "created_at_asc" then order(created_at: :asc)
    else                      order(created_at: :desc)
    end
  }

  def next_status_candidates
    self.class.statuses.keys.select { |s| can_transition_to?(s) }
  end
  def can_transition_to?(next_status)
    next_status = next_status.to_s
    return false unless self.class.statuses.key?(next_status)

    allowed = {
      "pending"    => %w[paid canceled failed],
      "paid"       => %w[processing canceled],
      "processing" => %w[shipped canceled],
      "shipped"    => %w[completed],
      "completed"  => %w[],
      "canceled"   => %w[],
      "failed"     => %w[]
    }

    allowed.fetch(status, []).include?(next_status)
  end

  def unique_product_count
    order_items.map { |oi| oi.product_variant.product_id }.uniq.size
  end
end
