class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    expected = ENV["ADMIN_API_TOKEN"]
    return head :unauthorized if expected.blank?

    auth = request.headers["Authorization"].to_s
    token = auth.match(/\ABearer (.+)\z/)&.

    return head :unauthorized if token.blank?
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(token, expected)
  end
end