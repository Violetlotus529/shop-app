class GuestOrdersController < ApplicationController
  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    num   = params[:guest_order_number].to_s.strip

    if email.blank? || num.blank?
      flash.now[:alert] = "入力内容に不備があります"
      render :new, status: :unprocessable_entity
      return
    end

    order = Order.find_by(guest_order_number: num)

    if order.nil? || order.customer_id.present? || order.customer_email.to_s.strip.downcase != email
      flash.now[:alert] = "注文が見つかりません"
      render :new, status: :not_found
      return
    end

    session[:guest_order_ids] = Array(session[:guest_order_ids]).map(&:to_i)
    session[:guest_order_ids] << order.id
    session[:guest_order_ids].uniq!

    redirect_to order_path(order), notice: "注文を表示しました"
  end
end
