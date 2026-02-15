class Admin::OrdersController < Admin::BaseController
  PER_PAGE = 20
  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    @q      = params[:q].to_s
    @status = params[:status].to_s
    @from   = params[:from].to_s
    @to     = params[:to].to_s
    @sort   = params[:sort].presence || "created_at_desc"

    scope = Order
      .includes(order_items: { product_variant: :product })
      .search_q(@q)
      .status_eq(@status)
      .created_from(@from)
      .created_to(@to)
      .sorted(@sort)

    @total = scope.count
    @total_pages = (@total.to_f / PER_PAGE).ceil
    @orders = scope
      .offset((@page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    @rows = @orders.map(&:admin_index_row)
  end

  def show
    @order = Order
      .includes(order_items: { product_variant: :product })
      .find(params[:id])
  end

  def status
    @order = Order.find(params[:id])
    next_status = params[:status].to_s

    unless Order.statuses.key?(next_status)
      redirect_to admin_order_path(@order), alert: "statusが不正です"
      return
    end

    unless @order.can_transition_to?(next_status)
      redirect_to admin_order_path(@order), alert: "不正なステータス遷移です"
      return
    end

    if next_status == "canceled"
      @order.cancel_and_restore_stock!
    else
      @order.update!(status: next_status)
    end

    redirect_to admin_order_path(@order), notice: "ステータスを更新しました"
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
