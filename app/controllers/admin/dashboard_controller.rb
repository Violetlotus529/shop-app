class Admin::DashboardController < Admin::BaseController
  PER_BLOCK = 5
  def show
    pending_scope = Order
      .includes(order_items: { product_variant: :product })
      .pending_only
      .order(created_at: :desc)

    today_scope = Order
      .includes(order_items: { product_variant: :product })
      .created_today
      .order(created_at: :desc)

    oos_scope = ProductVariant
      .includes(:product)
      .out_of_stock
      .order(updated_at: :desc)

    @pending_count = pending_scope.count
    @today_count   = today_scope.count
    @oos_count     = oos_scope.count

    @pending_rows = pending_scope.limit(PER_BLOCK).map(&:admin_dashboard_row)
    @today_rows   = today_scope.limit(PER_BLOCK).map(&:admin_dashboard_row)
    @oos_rows     = oos_scope.limit(PER_BLOCK).map(&:admin_out_of_stock_row)
  end
end