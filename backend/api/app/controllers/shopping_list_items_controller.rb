# frozen_string_literal: true

class ShoppingListItemsController < ApplicationController
  include ShoppingListItemJson

  before_action :authenticate_user!
  before_action :set_shopping_list

  def index
    items = @shopping_list.shopping_list_items.order(:ordem, :id)
    render json: { items: items.map { |item| shopping_list_item_payload(item) } }
  end

  def create
    permitted = shopping_list_item_params
    item = @shopping_list.shopping_list_items.build(permitted)
    item.ordem = next_ordem unless permitted.key?(:ordem)

    if item.save
      render json: shopping_list_item_payload(item), status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    item = @shopping_list.shopping_list_items.find(params[:id])
    if item.update(shopping_list_item_params)
      render json: shopping_list_item_payload(item)
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list item not found" }, status: :not_found
  end

  def destroy
    item = @shopping_list.shopping_list_items.find(params[:id])
    item.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list item not found" }, status: :not_found
  end

  private

  def set_shopping_list
    @shopping_list = current_user.shopping_lists.find(params[:shopping_list_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Shopping list not found" }, status: :not_found
  end

  def shopping_list_item_params
    params.permit(:product_canonical_id, :label, :quantidade, :ordem)
  end

  def next_ordem
    (@shopping_list.shopping_list_items.maximum(:ordem) || -1) + 1
  end
end
