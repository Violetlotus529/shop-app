class ProductsController < ApplicationController
  def index
    @products = Product.where(published: true, deleted: false)
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
