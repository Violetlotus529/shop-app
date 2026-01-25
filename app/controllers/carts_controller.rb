class CartsController < ApplicationController
  def show
    if customer_signed_in?
      @cart_items = current_customer.cart_items.includes(product_variant: :product)

      @total_cents = @cart_items.sum do |item|
        item.quantity * item.product_variant.product.price_cents
      end
    else
      cart = session[:cart]
      cart = {} unless cart.is_a?(Hash)

      variants = ProductVariant
        .includes(:product)
        .where(id: cart.keys)

      @guest_items = variants.map do |v|
        qty = cart[v.id.to_s].to_i

        {
          variant: v,
          quantity: qty,
          subtotal_cents: v.product.price_cents * qty
        }
      end

      @total_cents = @guest_items.sum { |row| row[:subtotal_cents] }
    end
  end
end
