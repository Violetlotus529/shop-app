class ApplicationController < ActionController::Base
  def index
    @products = Product.all
  end

  def after_sign_in_path_for(resource)
    return admin_root_path if resource.is_a?(AdminUser)
    super
  end
end
