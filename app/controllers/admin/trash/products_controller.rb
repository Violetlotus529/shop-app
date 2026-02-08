class Admin::Trash::ProductsController < Admin::BaseController
  PER_PAGE = 20
  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    @q    = params[:q].to_s
    @sort = params[:sort].presence || "deleted_at_desc"

    scope = Product
      .deleted_only
      .search_q(@q)
      .sorted(@sort)

    @total = scope.count
    @total_pages = (@total.to_f / PER_PAGE).ceil

    @products = scope
      .offset((@page - 1) * PER_PAGE)
      .limit(PER_PAGE)
  end

  def show
    @product = Product
      .deleted_only
      .includes(:product_variants)
      .find(params[:id])
  end
end
