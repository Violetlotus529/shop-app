class OrdersController < ApplicationController
  def show
    @order = Order.includes(order_items: { product_variant: :product }).find(params[:id])

    if customer_signed_in?
      raise ActiveRecord::RecordNotFound unless @order.customer_id == current_customer.id
    else
      guest_ids = Array(session[:guest_order_ids]).map(&:to_i)
      raise ActiveRecord::RecordNotFound unless guest_ids.include?(@order.id)
    end

    @paid_param = params[:paid].present?

    if !customer_signed_in? && @paid_param && @order.paid?
      session.delete(:cart)
    end

    @waiting_payment_confirmation = @paid_param && !@order.paid?
  end
end
