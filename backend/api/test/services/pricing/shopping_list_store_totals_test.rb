require "test_helper"

module Pricing
  class ShoppingListStoreTotalsTest < ActiveSupport::TestCase
    test "ranks stores by estimated total using disclosed unit only" do
      user = users(:one)
      store_cheap = Store.create!(cnpj: "11111111000191", nome: "Barato")
      store_exp = Store.create!(cnpj: "22222222000181", nome: "Caro")
      pc = ProductCanonical.create!(normalized_key: "SLST #{SecureRandom.hex(4)}", display_name: "Item único")

      [store_cheap, store_exp].each do |store|
        2.times do |i|
          receipt = user.receipts.create!(
            source_url: "https://example.com/nfe-#{store.id}-#{i}",
            status: "done",
            store_id: store.id,
            data_emissao: Date.current
          )
          price = store == store_cheap ? 5 : 9
          row = receipt.receipt_item_raws.create!(
            descricao_bruta: "Item",
            ordem: 0,
            quantidade: 1,
            valor_unitario: price,
            valor_total: price,
            product_canonical_id: pc.id
          )
          receipt.update!(valor_total: 50)
          ObservedPrice.create!(
            product_canonical_id: pc.id,
            store_id: store.id,
            receipt_item_raw_id: row.id,
            observed_on: Date.current,
            quantidade: 1,
            unidade: "UN",
            valor_unitario: price,
            valor_total: price
          )
        end
      end

      out = ShoppingListStoreTotals.call(
        product_lines: [{ product_canonical_id: pc.id, quantidade: 2 }]
      )

      assert_nil out[:shopping_list_id]
      assert_equal 1, out[:lines][:with_product]
      assert_equal 0, out[:lines][:without_product]
      assert_equal 2, out[:stores].size
      first = out[:stores].first
      last = out[:stores].last
      assert_equal store_cheap.id, first[:store_id]
      assert_equal "10.00", first[:estimated_total]
      assert_equal 1, first[:lines_covered]
      assert_equal 0, first[:lines_missing_price]
      assert_equal store_exp.id, last[:store_id]
      assert_equal "18.00", last[:estimated_total]
    ensure
      ObservedPrice.where(product_canonical_id: pc.id).delete_all if pc
      ReceiptItemRaw.where(product_canonical_id: pc.id).delete_all if pc
      Receipt.where(store_id: [store_cheap&.id, store_exp&.id].compact).delete_all if store_cheap && store_exp
      [store_cheap, store_exp].compact.each(&:destroy)
      pc&.destroy
    end

    test "includes store with single receipt for that product" do
      user = users(:one)
      store = Store.create!(cnpj: "33333333000181", nome: "Uma nota")
      pc = ProductCanonical.create!(normalized_key: "SLST2 #{SecureRandom.hex(4)}", display_name: "Prod")

      receipt = user.receipts.create!(
        source_url: "https://example.com/single",
        status: "done",
        store_id: store.id,
        data_emissao: Date.current
      )
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "Item",
        ordem: 0,
        quantidade: 1,
        valor_unitario: 3,
        valor_total: 3,
        product_canonical_id: pc.id
      )
      receipt.update!(valor_total: 10)
      ObservedPrice.create!(
        product_canonical_id: pc.id,
        store_id: store.id,
        receipt_item_raw_id: row.id,
        observed_on: Date.current,
        quantidade: 1,
        unidade: "UN",
        valor_unitario: 3,
        valor_total: 3
      )

      out = ShoppingListStoreTotals.call(product_lines: [{ product_canonical_id: pc.id, quantidade: 1 }])
      s = out[:stores].find { |row| row[:store_id] == store.id }
      assert_equal "3.00", s[:estimated_total]
      assert_equal 1, s[:lines_covered]
      assert_equal 0, s[:lines_missing_price]
    ensure
      ObservedPrice.where(product_canonical_id: pc.id).delete_all if pc
      ReceiptItemRaw.where(product_canonical_id: pc.id).delete_all if pc
      receipt&.destroy
      store&.destroy
      pc&.destroy
    end

    test "counts label-only lines as missing at every store" do
      user = users(:one)
      store = Store.create!(cnpj: "44444444000181", nome: "OK")
      pc = ProductCanonical.create!(normalized_key: "SLST3 #{SecureRandom.hex(4)}", display_name: "X")

      2.times do |i|
        receipt = user.receipts.create!(
          source_url: "https://example.com/d#{i}",
          status: "done",
          store_id: store.id,
          data_emissao: Date.current
        )
        row = receipt.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 4,
          valor_total: 4,
          product_canonical_id: pc.id
        )
        receipt.update!(valor_total: 20)
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: Date.current,
          quantidade: 1,
          unidade: "UN",
          valor_unitario: 4,
          valor_total: 4
        )
      end

      list = ShoppingList.create!(user: user, name: "Mix")
      list.shopping_list_items.create!(product_canonical_id: pc.id, quantidade: 1, ordem: 0, label: nil)
      list.shopping_list_items.create!(product_canonical_id: nil, quantidade: 1, ordem: 1, label: "sem id")

      out = ShoppingListStoreTotals.call(shopping_list: list)
      assert_equal list.id, out[:shopping_list_id]
      assert_equal 2, out[:lines][:total]
      assert_equal 1, out[:lines][:without_product]
      s = out[:stores].first
      assert_equal 1, s[:lines_covered]
      assert_equal 1, s[:lines_missing_price]
    ensure
      list&.destroy
      ObservedPrice.where(product_canonical_id: pc.id).delete_all if pc
      ReceiptItemRaw.where(product_canonical_id: pc.id).delete_all if pc
      Receipt.where(store_id: store.id).delete_all if store
      store&.destroy
      pc&.destroy
    end

    test "empty list returns no stores" do
      user = users(:one)
      list = ShoppingList.create!(user: user, name: "Vazia")
      out = ShoppingListStoreTotals.call(shopping_list: list)
      assert_equal [], out[:stores]
      assert_equal 0, out[:lines][:total]
    ensure
      list&.destroy
    end
  end
end
