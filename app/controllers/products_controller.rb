class ProductsController < ApplicationController
  PER_PAGE = 20
  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    @q        = params[:q].to_s
    @category = params[:category].presence || "all"
    @sort     = params[:sort].presence || "updated_at_desc"

    scope = Product
      .public_visible
      .search_q(@q)
      .category_eq(@category)
      .sorted_public(@sort)
    
    @total = scope.count
    @total_pages = (@total.to_f / PER_PAGE).ceil

    @products = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @product = Product.find_by!(
      id: params[:id],
      published: true,
      deleted: false
    )

    @variants = @product.product_variants
                        .where(deleted: false)
                        .order(:color, :size)
  end
end
