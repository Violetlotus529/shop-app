class CartItemsController < ApplicationController
  def create
    variant = ProductVariant
      .joins(:product)
      .where(product: { published: true, deleted: false })
      .where(product_variants: { deleted: false })
      .find(params[:product_variant_id])

    qty = Integer(params[:quantity])
    qty = 1 if qty < 1

    if variant.stock <= 0
      redirect_back fallback_location: product_path(variant.product), alert: "在庫がありません"
      return
    end

    if customer_signed_in?
      item = CartItem.find_or_initialize_by(customer: current_customer, product_variant: variant)
      item.quantity = (item.quantity || 0) + qty
      item.save!
    else
      cart = session[:cart] ||= {}
      key = variant.id.to_s
      cart[key] = cart.fetch(key, 0).to_i + qty
    end

    redirect_to cart_path, notice: "カートに追加しました"
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: products_path, alert: "商品が見つかりません"
  rescue ArgumentError
    redirect_back fallback_location: products_path, alert: "数量が不正です"
  end

  def update
    qty = Integer(params[:quantity])
    qty = 1 if qty < 1

    if customer_signed_in?
      item = current_customer.cart_items.find(params[:id])
      item.update!(quantity: qty)
    else
      cart = session[:cart] ||= {}
      key = params[:id].to_s
      raise ActiveRecord::RecordNotFound unless cart.key?(key)
      cart[key] = qty
    end
    redirect_to cart_path, notice: "数量を更新しました"
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "対象が見つかりません"
  rescue ArgumentError
    redirect_to cart_path, alert: "数量が不正です"
  end

  def destroy
    if customer_signed_in?
      item = current_customer.cart_items.find(params[:id])
      item.destroy!
    else
      cart = session[:cart] ||= {}
      key = params[:id].to_s
      cart.delete(key)
    end
    redirect_to cart_path, notice: "削除しました"
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "対象商品が見つかりません"
  end
end
