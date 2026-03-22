class AuthController < ApplicationController
  def login
    user = User.authenticate_by(email: login_params[:email], password: login_params[:password])
    if user
      render json: {
        token: user.generate_token_for(:api),
        user: { id: user.id, email: user.email }
      }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
