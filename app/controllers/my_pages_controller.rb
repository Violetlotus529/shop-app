class MyPagesController < ApplicationController
  before_action :authenticate_customer!

  def show
    @customer = current_customer
  end

  def update
    @customer = current_customer

    if @customer.update(customer_params)
      redirect_to my_page_path, notice: "更新しました"
    else
      flash.now[:alert] = "入力内容を確認してください"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def customer_params
    params.require(:customer).permit(
      :name,
      :postal_code,
      :prefecture,
      :city,
      :address_line1,
      :address_line2,
      :phone_number
    )
  end
end
