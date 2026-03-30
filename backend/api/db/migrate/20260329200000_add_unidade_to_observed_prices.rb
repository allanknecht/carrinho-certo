# frozen_string_literal: true

class AddUnidadeToObservedPrices < ActiveRecord::Migration[8.0]
  def change
    add_column :observed_prices, :unidade, :string, limit: 10
  end
end
