class CheckoutsController < ApplicationController
  def create
    rows = build_cart_rows!

    total_cents = rows.sum { |r| r[:subtotal_cents] }
    raise ActiveRecord::RecordInvalid if total_cents <= 0

    order = Order.create!(
      customer: (customer_signed_in? ? current_customer : nil),
      status: :pending,
      total_cents: total_cents,
      customer_name: customer_signed_in? ? current_customer.name : params[:customer_name],
      customer_email: customer_signed_in? ? current_customer.email : params[:customer_email],
      postal_code: customer_signed_in? ? current_customer.postal_code : params[:postal_code],
      prefecture: customer_signed_in? ? current_customer.prefecture : params[:prefecture],
      city: customer_signed_in? ? current_customer.city : params[:city],
      address_line1: customer_signed_in? ? current_customer.address_line1 : params[:address_line1],
      address_line2: customer_signed_in? ? current_customer.address_line2 : params[:address_line2]
    )

    unless customer_signed_in?
      session[:guest_order_ids] = Array(session[:guest_order_ids])
      session[:guest_order_ids] << order.id
      session[:guest_order_ids].uniq!
    end

    rows.each do |r|
      OrderItem.create!(
        order: order,
        product_variant: r[:variant],
        quantity: r[:qty],
        unit_price_cents: r[:unit_price_cents],
        subtotal_cents: r[:subtotal_cents]
      )
    end

    session_obj = Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: rows.map { |r|
        {
          price_data: {
            currency: "jpy",
            product_data: { name: r[:variant].product.name },
            unit_amount: r[:unit_price_cents]
          },
          quantity: r[:qty]
        }
      },
      success_url: order_url(order, paid: 1),
      cancel_url:  cart_url,
      metadata: { order_id: order.id }
    )
    order.update!(stripe_checkout_session_id: session_obj.id)
    redirect_to session_obj.url, allow_other_host: true
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "商品が見つかりません"
  rescue ArgumentError
    redirect_to cart_path, alert: "数量が不正です"
  rescue => e
    Rails.logger.error(e.full_message)
    raise
  end

  private

  def build_cart_rows!
    if customer_signed_in?
      items = current_customer.cart_items.includes(product_variant: :product)
      variants = items.map(&:product_variant)
      qty_map = items.index_by { |i| i.product_variant_id }.transform_values(&:quantity)
    else
      cart = session[:cart]
      cart = {} unless cart.is_a?(Hash)
      variants = ProductVariant.includes(:product).where(id: cart.keys)
      qty_map = cart.transform_keys(&:to_i).transform_values { |v| Integer(v) rescue 0 }
    end

    variants.each do |v|
      raise ActiveRecord::RecordNotFound if v.deleted? || v.product.deleted? || !v.product.published?
      qty = qty_map[v.id].to_i
      raise ArgumentError if qty < 1
      raise ArgumentError if v.stock < qty
    end

    variants.map do |v|
      qty = qty_map[v.id].to_i
      unit = v.product.price_cents
      {
        variant: v,
        qty: qty,
        unit_price_cents: unit,
        subtotal_cents: unit * qty
      }
    end
  end
end
