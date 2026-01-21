class Admin::ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update]
  def index
    @products = Product.active.order(updated_at: :desc)
  end

  def show
  end

  def new
    @product = Product.new
  end

  def edit
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
    params.require(:product).permit(:name, :description, :price_cents, :published)
  end
end