class Admin::InventoriesController < Admin::BaseController
  def index
    @q = params[:q].to_s
    @sort = params[:sort].presence || "updated_at_desc"

    scope = ProductVariant
      .includes(:product)
      .joins(:product)
      .where(product_variants: { deleted: false })
      .where(products: { deleted: false })

    if @q.present?
      s = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"
      scope = scope.where(
        "products.name LIKE :s
         OR product_variants.color LIKE :s
         OR product_variants.size LIKE :s
         OR product_variants.sku LIKE :s",
        s: s
      )
    end

    scope =
      case @sort
      when "stock_asc"
        scope.order(stock: :asc)
      when "stock_desc"
        scope.order(stock: :desc)
      else
        scope.order(updated_at: :desc)
      end
  end
end