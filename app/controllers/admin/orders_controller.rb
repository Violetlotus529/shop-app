class Admin::OrdersController < Admin::BaseController
  PER_PAGE = 20
  def index
    page = params[:page].to_i
    page = 1 if page < 1

    scope = Order
      .search_q(params[:q])
      .status_eq(params[:status])
      .created_from(params[:from])
      .created_to(params[:to])
      .sorted(params[:sort])

    total = scope.count
    total_pages = (total.to_f / PER_PAGE).ceil
    orders = scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

    render json: {
      orders: orders.map { |o| index_json(o) },
      pagination: { current: page, total_pages: total_pages }
    }
  end

  def show
    order = Order.includes(order_items: { product_variant: :product }).find(params[:id])
    render json: show_json(order)
  end

  def status
    order = Order.find(params[:id])
    next_status = params[:status].to_s

    return render(json: { message: "statusが欠落・定義外です" }, status: :bad_request) if next_status.blank?
    return render(json: { message: "statusが欠落・定義外です" }, status: :bad_request) unless Order.statuses.key?(next_status)

    unless order.can_transition_to?(next_status)
      return render(json: { message: "不正なステータス遷移です" }, status: :unprocessable_entity)
    end

    order.update!(status: next_status)
    render json: { id: order.id, message: "ステータスを更新しました。" }
  end

  private

  def index_json(o)
    {
      id: o.id,
      order_number: o.respond_to?(:order_number) ? o.order_number : nil,
      created_at: o.created_at&.iso8601,
      customer_type: o.customer_id.present? ? "member" : "guest",
      customer_email: o.customer_email,
      customer_name: o.customer_name,
      status: o.status,
      payment_method: "credit",
      item_count: o.order_items.size,
      total_amount: o.total_cents
    }
  end

  def show_json(o)
    {
      id: o.id,
      order_number: o.respond_to?(:order_number) ? o.order_number : nil,

      status: o.status,
      payment_method: "credit",
      total_amount: o.total_cents,
      item_count: o.order_items.sum(&:quantity),

      created_at: o.created_at&.iso8601,
      paid_at: o.paid_at&.iso8601,
      shipped_at: o.respond_to?(:shipped_at) ? o.shipped_at&.iso8601 : nil,
      completed_at: o.respond_to?(:completed_at) ? o.completed_at&.iso8601 : nil,
      canceled_at: o.respond_to?(:canceled_at) ? o.canceled_at&.iso8601 : nil,

      customer: {
        type: o.customer_id.present? ? "member" : "guest",
        name: o.customer_name,
        email: o.customer_email,
        postal_code: o.postal_code,
        prefecture: o.prefecture,
        city: o.city,
        address_line1: o.address_line1,
        address_line2: o.address_line2
      },

      order_items: o.order_items.map { |item| 
        v = item.product_variant
        p = v.product
        {
          product_id: p.id,
          product_name: p.name,
          color: v.color,
          size: v.size,
          quantity: item.quantity,
          unit_price: item.unit_price_cents,
          subtotal: item.subtotal_cents
        }
      }
    }
  end
end
