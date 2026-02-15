class Admin::InventoriesController < Admin::BaseController
  def index
    @q = params[:q].to_s
    @sort = params[:sort].presence || "updated_at_desc"

    scope = ProductVariant
      .includes(:product)
      .where(deleted: false)

    if @q.present?
      s = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"
      scope = scope.where(
        "products.name LIKE :s OR product_variants.color LIKE :s OR product_variants.size LIKE :s OR product_variants.sku LIKE :s",
        s: s
      ).references(:products)
    end

    scope =
      case @sort
      when "stock_asc"  then scope.order(stock: :asc)
      when "stock_desc" then scope.order(stock: :desc)
      else                   scope.order(updated_at: :desc)
      end
    @variants = scope.limit(200)
  end
end