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
    failed: 6,
    refunded: 7
  }

  STATUS_LABELS = {
    "pending"    => "支払い待ち",
    "paid"       => "支払い完了",
    "processing" => "発送準備中",
    "shipped"    => "発送済み",
    "completed"  => "完了",
    "canceled"   => "キャンセル",
    "failed"     => "決済失敗",
    "refunded"   => "返金済み"
  }.freeze

  def refunded?
    status == "refunded"
  end

  def status_label
    STATUS_LABELS.fetch(status) { status }
  end

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
      "pending"    => %w[failed],
      "paid"       => %w[processing canceled],
      "processing" => %w[shipped canceled],
      "shipped"    => %w[completed],
      "completed"  => %w[],
      "canceled"   => %w[],
      "failed"     => %w[],
      "refunded"   => %w[]
    }

    allowed.fetch(status, []).include?(next_status)
  end

  def admin_index_row
    first_item = order_items.first
    v = first_item&.product_variant
    p = v&.product

    product_count = order_items.map { |oi| oi.product_variant.product_id }.uniq.size
    other_count = [product_count - 1, 0].max

    {
      id: id,
      created_at: created_at,
      order_number: (respond_to?(:order_number) ? order_number : nil),
      status: status,
      status_label: status_label,
      payment_method: "credit",
      customer_name: customer_name,
      customer_email: customer_email,
      total_cents: total_cents,
      product_name: p&.name,
      variant_label: (v ? "#{v.color}/#{v.size}" : nil),
      other_count: other_count,
      image: p&.main_image_url_or_nil
    }
  end

  def admin_primary_item
    order_items.first
  end

  def admin_primary_variant
    admin_primary_item&.product_variant
  end

  def admin_primary_product
    admin_primary_variant&.product
  end

  scope :pending_only, -> { where(status: statuses.fetch("pending"))}

  scope :created_today, -> {
    from = Time.zone.now.beginning_of_day
    to = Time.zone.now.end_of_day
    where(created_at: from..to)
  }

  def admin_dashboard_row
    {
      id: id,
      created_at: created_at,
      order_number: (respond_to?(:order_number) ? order_number : nil),
      payment_method: "credit"
    }
  end

  def cancel_and_restore_stock!
    with_lock do
      return if canceled?
      should_restore = paid? || processing?

      Order.transaction do
        if should_restore
          qty_by_variant_id =
            order_items
              .group_by(&:product_variant_id)
              .transform_values { |items| items.sum(&:quantity) }

          variant_ids = qty_by_variant_id.keys.sort
          variants = ProductVariant.lock.where(id: variant_ids).index_by(&:id)

          variant_ids.each do |vid|
            v = variants.fetch(vid)
            v.update!(stock: v.stock + qty_by_variant_id.fetch(vid))
          end
        end
        update!(status: :canceled)
      end
    end
  end
end
