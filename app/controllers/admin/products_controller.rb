class Admin::ProductsController < Admin::BaseController
  PER_PAGE = 20
  before_action :set_product, only: %i[show edit update]
  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    @q      = params[:q].to_s
    @status = params[:status].presence || "all"
    @sort   = params[:sort].presence || "updated_at_desc"

    scope = Product
      .active
      .search_q(@q)
      .publish_state(@status)
      .sorted(@sort)

    @total = scope.count
    @total_pages = (@total.to_f / PER_PAGE).ceil

    @products = scope
      .offset((@page - 1) * PER_PAGE)
      .limit(PER_PAGE)
  end

  def show
  end

  def new
    @product = Product.new
    @product.product_variants.build
  end

  def edit
    @product.product_variants.build
  end
  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_product_path(@product), notice: "保存しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def deleted
    @product = Product.find(params[:id])
    @product.update!(deleted: !@product.deleted)
    redirect_to admin_products_path, notice: "更新しました"
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :price_cents,
      :published,
      :category,
      product_variants_attributes: [
        :id,
        :color,
        :size,
        :sku,
        :_destroy
      ]
    )
  end
end