# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :authenticate_user!

  DEFAULT_PER = 20
  MAX_PER = 100

  def index
    scope = ProductCanonical.order(:display_name)
    q = params[:q].to_s.strip
    if q.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      scope = scope.where(
        "products_canonical.display_name ILIKE :like OR products_canonical.normalized_key ILIKE :like",
        like: like
      )
    end

    page = [params[:page].to_i, 1].max
    raw_per = params[:per].presence&.to_i
    per = raw_per&.positive? ? raw_per : DEFAULT_PER
    per = [per, MAX_PER].min

    total = scope.count
    records = scope.offset((page - 1) * per).limit(per)
    total_pages = total.zero? ? 0 : (total.to_f / per).ceil

    render json: {
      products: records.map { |p| product_json(p) },
      meta: {
        page: page,
        per: per,
        total: total,
        total_pages: total_pages
      }
    }
  end

  private

  def product_json(product)
    {
      id: product.id,
      display_name: product.display_name,
      normalized_key: product.normalized_key
    }
  end
end
