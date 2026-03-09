class Admin::Api::InventoriesController < Admin::BaseController
  def index
    scope = ProductVariant
      .includes(:product)
      .joins(:product)
      .where(deleted: false)
      .where(products: { deleted: false })

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.joins(:product).where(
        "products.name ILIKE ? OR product_variants.color ILIKE ? OR product_variants.size ILIKE ?",
        q, q, q
      )
    end

    case params[:stock_state]
    when "in_stock"
      scope = scope.where("stock > 0")
    when "out_of_stock"
      scope = scope.where(stock: 0)
    when "low"
      scope = scope.where(stock: 1..4)
    else
    end

    case params[:sort]
    when "stock_asc"
      scope = scope.order(stock: :asc)
    when "stock_desc"
      scope = scope.order(stock: :desc)
    else
      scope = scope.order(updated_at: :desc)
    end

    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 20
    total = scope.count
    total_pages = (total.to_f / per_page).ceil
    variants = scope.limit(per_page).offset((page - 1) * per_page)

    render json: {
      variants: variants.map { |v|
        {
          id: v.id,
          product_name: v.product.name,
          color: v.color,
          size: v.size,
          stock: v.stock,
          updated_at: v.updated_at&.iso8601
        }
      },
      pagination: {
        current_page: page,
        total_pages: total_pages
      }
    }
  end

  def bulk_update
    variants = params.require(:variants)
    raise ActionController::BadRequest, "variants must be an array" unless variants.is_a?(Array)

    updated_count = 0

    ProductVariant.transaction do
      variants.each do |row|
        # row は HashWithIndifferentAccess にならないケースがあるので両対応
        id_raw    = row[:id]    || row["id"]
        stock_raw = row[:stock] || row["stock"]

        raise ActionController::BadRequest, "id is required" if id_raw.blank?
        raise ActionController::BadRequest, "stock is required" if stock_raw.nil?

        stock_i = Integer(stock_raw)
        raise ActiveRecord::RecordInvalid.new(ProductVariant.new), "stock must be >= 0" if stock_i < 0

        variant = ProductVariant.where(deleted: false).find(id_raw)
        variant.update!(stock: stock_i)
        updated_count += 1
      end
    end

    render json: {
      updated_count: updated_count,
      message: "在庫を更新しました。"
    }
  rescue ActionController::ParameterMissing => e
    render json: { error: "BAD_REQUEST", message: e.message }, status: :bad_request
  rescue ActionController::BadRequest => e
    render json: { error: "BAD_REQUEST", message: e.message }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "NOT_FOUND", message: "対象が存在しません。" }, status: :not_found
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    render json: { error: "VALIDATION_ERROR", message: e.message }, status: :unprocessable_entity
  end
end