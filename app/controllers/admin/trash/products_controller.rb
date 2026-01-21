class Admin::Trash::ProductsController < ApplicationController
  before_action :set_product, only: :show
  def index
    @product = Product.where(deleted: true).order(updated_at: :desc)
  end

  def show
  end

  private

  def set_product
    @product = Product.find_by!(id: params[:id], deleted: true)
  end
end
