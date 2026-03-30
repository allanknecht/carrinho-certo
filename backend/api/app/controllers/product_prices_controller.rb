# frozen_string_literal: true

class ProductPricesController < ApplicationController
  before_action :authenticate_user!

  def show
    summary = Pricing::ProductPricesSummary.call(product_canonical_id: params[:id])

    if summary[:error] == :not_found
      render json: { error: "Product not found" }, status: :not_found
    else
      render json: summary.except(:error)
    end
  end
end
