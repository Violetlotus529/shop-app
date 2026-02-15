class CartsController < ApplicationController
  def show
    if customer_signed_in?
      items = current_customer.cart_items.includes(product_variant: :product)
      
      @cart_rows = items.map do |item|
        v = item.product_variant
        qty = item.quantity.to_i
        {
          key: item.id,
          variant: v,
          quantity:  qty,
          subtotal_cents: v.product.price_cents * qty,
          stock_ok: v.stock >= qty
        }
      end
      @total_cents = @cart_rows.sum { |r| r[:subtotal_cents] }
    else
      cart = session[:cart]
      cart = {} unless cart.is_a?(Hash)

      variants = ProductVariant
        .includes(:product)
        .where(id: cart.keys)

      @cart_rows = variants.map do |v|
        qty = cart[v.id.to_s].to_i
        {
          key: v.id,
          variant: v,
          quantity: qty,
          subtotal_cents: v.product.price_cents * qty,
          stock_ok: v.stock >= qty
        }
      end

      @total_cents = @cart_rows.sum { |row| row[:subtotal_cents] }
    end

    @has_stock_error = @cart_rows.any? { |r| !r[:stock_ok] }
  end
end
