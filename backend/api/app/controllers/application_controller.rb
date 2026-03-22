class ApplicationController < ActionController::API
  private

  def authenticate_user!
    token = bearer_token
    @current_user = User.find_by_token_for(:api, token) if token.present?
    return if @current_user

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def current_user
    @current_user
  end

  def bearer_token
    request.authorization.to_s.sub(/\ABearer /i, "")
  end
end
