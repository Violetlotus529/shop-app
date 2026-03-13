class OrdersController < ApplicationController
  before_action :authenticate_customer!, only: :index
  
  def index
    @orders =
      current_customer
        .orders
        .includes(:order_items)
        .order(created_at: :desc)
  end
  
  def show
    if customer_signed_in?
      @order = current_customer
        .orders
        .includes(order_items: { product_variant: :product })
        .find(params[:id])
    else
      @order = Order
        .includes(order_items: { product_variant: :product })
        .find(params[:id])

      guest_ids = Array(session[:guest_order_ids]).map(&:to_i)
      raise ActiveRecord::RecordNotFound unless guest_ids.include?(@order.id)
    end

    @paid_param = params[:paid].present?

    if @paid_param && @order.paid?
      if customer_signed_in?
        current_customer.cart_items.destroy_all
      else
        session.delete(:cart)
      end
    end

    @waiting_payment_confirmation = @paid_param && !@order.paid?
  end
end
