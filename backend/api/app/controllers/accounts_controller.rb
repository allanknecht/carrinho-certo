# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email
      }
    }
  end

  def destroy
    current_user.destroy!
    head :no_content
  end
end
