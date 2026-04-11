# frozen_string_literal: true

class ShoppingListsController < ApplicationController
  include ShoppingListItemJson

  before_action :authenticate_user!

  def index
    lists = current_user.shopping_lists.order(updated_at: :desc).includes(:shopping_list_items)
    render json: { shopping_lists: lists.map { |list| list_payload(list, include_items: false) } }
  end

  def show
    list = current_user.shopping_lists.includes(:shopping_list_items).find(params[:id])
    render json: list_payload(list, include_items: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list not found" }, status: :not_found
  end

  def create
    list = current_user.shopping_lists.build(shopping_list_params)
    if list.save
      render json: list_payload(list, include_items: true), status: :created
    else
      render json: { errors: list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    list = current_user.shopping_lists.find(params[:id])
    if list.update(shopping_list_params)
      list.reload
      render json: list_payload(list, include_items: true)
    else
      render json: { errors: list.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list not found" }, status: :not_found
  end

  def destroy
    list = current_user.shopping_lists.find(params[:id])
    list.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list not found" }, status: :not_found
  end

  def store_rankings
    list = current_user.shopping_lists.find(params[:id])
    render json: Pricing::ShoppingListStoreTotals.call(shopping_list: list)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list not found" }, status: :not_found
  end

  private

  def shopping_list_params
    params.permit(:name)
  end

  def list_payload(list, include_items:)
    items_relation = list.shopping_list_items
    payload = {
      id: list.id,
      name: list.name,
      items_count: items_relation.loaded? ? items_relation.size : items_relation.count,
      created_at: list.created_at.iso8601(3),
      updated_at: list.updated_at.iso8601(3)
    }
    if include_items
      ordered = items_relation.loaded? ? items_relation.sort_by { |i| [i.ordem, i.id] } : items_relation.order(:ordem, :id)
      payload[:items] = ordered.map { |item| shopping_list_item_payload(item) }
    end
    payload
  end

end
