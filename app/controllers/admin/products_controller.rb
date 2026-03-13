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
    flag = ActiveModel::Type::Boolean.new.cast(params[:deleted])

    @product.update!(deleted: flag)
    redirect_to admin_products_path, notice: "更新しました"
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: admin_products_path, alert: e.record.errors.full_messages.join(", ")
  end

  def purge_main_image
    @product = Product.find(params[:id])

    unless @product.main_image.attached?
      redirect_to edit_admin_product_path(@product), alert: "画像がありません"
      return
    end

    @product.main_image.purge
    redirect_to edit_admin_product_path(@product), notice: "画像を削除しました"
  rescue ActiveRecord::RecordNorFound
    redirect_to admin_products_path, alert: "商品が見つかりません"
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
      :main_image,
      product_variants_attributes: [
        :id,
        :color,
        :size,
        :sku,
        :deleted
      ]
    )
  end
end