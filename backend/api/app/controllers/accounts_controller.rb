# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    current_user.destroy!
    head :no_content
  end
end
