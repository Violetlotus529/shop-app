class CartItemsController < ApplicationController
# app/controllers/cart_items_controller.rb
  def create
    variant = ProductVariant
      .joins(:product)
      .where(product: { published: true, deleted: false })
      .where(product_variants: { deleted: false })
      .find(params[:product_variant_id])

    qty = Integer(params[:quantity]) rescue 1
    qty = 1 if qty < 1

    existing_qty =
      if customer_signed_in?
        CartItem.where(customer: current_customer, product_variant: variant).pick(:quantity).to_i
      else
        cart = session[:cart]
        cart = {} unless cart.is_a?(Hash)
        cart[variant.id.to_s].to_i
      end

    new_qty = existing_qty + qty

    if variant.stock <= 0
      redirect_back fallback_location: product_path(variant.product), alert: "在庫がありません"
      return
    end

    if new_qty > variant.stock
      redirect_back fallback_location: product_path(variant.product),
                    alert: "在庫数を超えています（在庫: #{variant.stock} / 現在: #{existing_qty} / 追加: #{qty}）"
      return
    end

    if customer_signed_in?
      item = CartItem.find_or_initialize_by(customer: current_customer, product_variant: variant)
      item.quantity = new_qty
      item.save!
    else
      session[:cart] ||= {}
      session[:cart][variant.id.to_s] = new_qty
    end

    redirect_to cart_path, notice: "カートに追加しました"
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: products_path, alert: "商品が見つかりません"
  end

  def update
    qty = Integer(params[:quantity])
    qty = 1 if qty < 1

    if customer_signed_in?
      item = current_customer.cart_items.find(params[:id])
      v = item.product_variant

      if qty > v.stock
        redirect_to cart_path, alert: "在庫数を超えています (在庫: #{v.stock}) "
        return
      end

      item.update!(quantity: qty)
    else
      cart = session[:cart] ||= {}
      key = params[:id].to_s
      raise ActiveRecord::RecordNotFound unless cart.key?(key)

      v = ProductVariant
        .joins(:product)
        .where(product: { published: true, deleted: false })
        .where(product_variants: { deleted: false })
        .find(key)

      if qty > v.stock
        redirect_to cart_path, alert: "在庫数を超えています (在庫: #{v.stock}) "
        return
      end

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
