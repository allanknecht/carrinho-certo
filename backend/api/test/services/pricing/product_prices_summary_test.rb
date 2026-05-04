require "test_helper"

module Pricing
  class ProductPricesSummaryTest < ActiveSupport::TestCase
    test "returns not_found when product id missing" do
      out = ProductPricesSummary.call(product_canonical_id: 999_999)
      assert_equal :not_found, out[:error]
    end

    test "one receipt per store exposes latest price for that store" do
      user = users(:one)
      store = Store.create!(cnpj: "11111111000191", nome: "Loja A")
      receipt = user.receipts.create!(
        source_url: "https://example.com/nfe",
        status: "done",
        store_id: store.id,
        data_emissao: Date.current
      )
      pc = ProductCanonical.create!(normalized_key: "TEST PROD #{SecureRandom.hex(4)}", display_name: "Produto teste")
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "Item",
        ordem: 0,
        quantidade: 1,
        valor_unitario: 10,
        valor_total: 10,
        product_canonical_id: pc.id
      )
      receipt.update!(valor_total: 99.99)
      ObservedPrice.create!(
        product_canonical_id: pc.id,
        store_id: store.id,
        receipt_item_raw_id: row.id,
        observed_on: Date.current,
        quantidade: 1,
        unidade: "UN",
        valor_unitario: 10,
        valor_total: 10
      )

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_nil out[:error]
      assert_equal pc.id, out[:product][:id]
      assert_equal 1, out[:stores].size
      s = out[:stores].first
      assert_equal store.id, s[:store_id]
      assert_equal "10.00", s[:unit_price]
      assert_equal Date.current.iso8601, s[:observed_on]
    end

    test "picks latest observation by emission date when store has several receipts" do
      user = users(:one)
      store = Store.create!(cnpj: "33333333000181", nome: "Loja C")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD2 #{SecureRandom.hex(4)}", display_name: "Produto dois")

      d_old = Date.new(2024, 1, 10)
      d_new = Date.new(2025, 6, 1)

      [ d_old, d_new ].each_with_index do |emissao, i|
        receipt = user.receipts.create!(
          source_url: "https://example.com/nfe#{i}",
          status: "done",
          store_id: store.id,
          data_emissao: emissao
        )
        row = receipt.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 10 + i,
          valor_total: 10 + i,
          product_canonical_id: pc.id
        )
        receipt.update!(valor_total: 50 + i)
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: emissao,
          quantidade: 1,
          unidade: "UN",
          valor_unitario: 10 + i,
          valor_total: 10 + i
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      s = out[:stores].first
      assert_equal "11.00", s[:unit_price]
      assert_equal d_new.iso8601, s[:observed_on]
    end

    test "each store gets its own latest row" do
      user = users(:one)
      store_a = Store.create!(cnpj: "44444444000181", nome: "Mercado A")
      store_b = Store.create!(cnpj: "55555555000181", nome: "Mercado B")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD3 #{SecureRandom.hex(4)}", display_name: "Produto mix")

      r_a = user.receipts.create!(
        source_url: "https://example.com/a",
        status: "done",
        store_id: store_a.id,
        data_emissao: Date.current
      )
      row_a = r_a.receipt_item_raws.create!(
        descricao_bruta: "Item",
        ordem: 0,
        quantidade: 1,
        valor_unitario: 5,
        valor_total: 5,
        product_canonical_id: pc.id
      )
      ObservedPrice.create!(
        product_canonical_id: pc.id,
        store_id: store_a.id,
        receipt_item_raw_id: row_a.id,
        observed_on: Date.current,
        quantidade: 1,
        valor_unitario: 5,
        valor_total: 5
      )

      r_b = user.receipts.create!(
        source_url: "https://example.com/b",
        status: "done",
        store_id: store_b.id,
        data_emissao: Date.current
      )
      row_b = r_b.receipt_item_raws.create!(
        descricao_bruta: "Item",
        ordem: 0,
        quantidade: 1,
        valor_unitario: 20,
        valor_total: 20,
        product_canonical_id: pc.id
      )
      ObservedPrice.create!(
        product_canonical_id: pc.id,
        store_id: store_b.id,
        receipt_item_raw_id: row_b.id,
        observed_on: Date.current,
        quantidade: 1,
        valor_unitario: 20,
        valor_total: 20
      )

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      by_nome = out[:stores].index_by { |x| x[:nome] }
      assert_equal "5.00", by_nome["Mercado A"][:unit_price]
      assert_equal "20.00", by_nome["Mercado B"][:unit_price]
    end

    test "two lines same product on one receipt yields one row per store (DISTINCT ON store)" do
      user = users(:one)
      store = Store.create!(cnpj: "99999999000181", nome: "Duas Linhas Mesma Nota")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD6 #{SecureRandom.hex(4)}", display_name: "Produto duplicado na NFC-e")
      r = user.receipts.create!(
        source_url: "https://example.com/double-line",
        status: "done",
        store_id: store.id,
        data_emissao: Date.current
      )
      rows = []
      2.times do |i|
        rows << r.receipt_item_raws.create!(
          descricao_bruta: "Item #{i}",
          ordem: i,
          quantidade: 1,
          valor_unitario: 10 + i,
          valor_total: 10 + i,
          product_canonical_id: pc.id
        )
      end
      rows.each do |row|
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: Date.current,
          quantidade: 1,
          valor_unitario: row.valor_unitario,
          valor_total: row.valor_total
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal 1, out[:stores].size
      # Same observed_on: tie-break by updated_at — second row created last wins
      assert_equal "11.00", out[:stores].first[:unit_price]
    end

    test "old emission outside any short window still wins if it is the only row" do
      user = users(:one)
      store = Store.create!(cnpj: "88888888000181", nome: "Histórico longo")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD7 #{SecureRandom.hex(4)}", display_name: "Fora de janela curta")

      emissao = Date.new(2020, 3, 1)
      receipt = user.receipts.create!(
        source_url: "https://example.com/old",
        status: "done",
        store_id: store.id,
        data_emissao: emissao
      )
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "Item",
        ordem: 0,
        quantidade: 1,
        valor_unitario: 7,
        valor_total: 7,
        product_canonical_id: pc.id
      )
      ObservedPrice.create!(
        product_canonical_id: pc.id,
        store_id: store.id,
        receipt_item_raw_id: row.id,
        observed_on: emissao,
        quantidade: 1,
        valor_unitario: 7,
        valor_total: 7
      )

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal "7.00", out[:stores].first[:unit_price]
      assert_equal emissao.iso8601, out[:stores].first[:observed_on]
    end
  end
end
