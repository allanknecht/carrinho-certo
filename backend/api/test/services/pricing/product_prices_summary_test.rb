require "test_helper"

module Pricing
  class ProductPricesSummaryTest < ActiveSupport::TestCase
    test "returns not_found when product id missing" do
      out = ProductPricesSummary.call(product_canonical_id: 999_999)
      assert_equal :not_found, out[:error]
    end

    test "hides prices at store until two distinct receipts there" do
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
      assert_equal 1, out[:observations_count]
      assert_equal 1, out[:receipts_distinct_count]
      assert_equal false, out[:prices_disclosed]
      assert_nil out[:relevant_price]
      s = out[:stores].first
      assert_equal false, s[:prices_disclosed]
      assert_equal 1, s[:receipts_distinct_at_store]
      assert_empty s[:recent_prices]
    end

    test "discloses up to three recent prices when store has two plus receipts" do
      user = users(:one)
      store = Store.create!(cnpj: "33333333000181", nome: "Loja C")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD2 #{SecureRandom.hex(4)}", display_name: "Produto dois")

      2.times do |i|
        receipt = user.receipts.create!(
          source_url: "https://example.com/nfe#{i}",
          status: "done",
          store_id: store.id,
          data_emissao: Date.current
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
          observed_on: Date.current,
          quantidade: 1,
          unidade: "UN",
          valor_unitario: 10 + i,
          valor_total: 10 + i
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal true, out[:prices_disclosed]
      assert_equal 2, out[:receipts_distinct_count]
      assert_equal "11.00", out[:relevant_price][:unit_price]
      assert_equal "latest_among_verified_stores", out[:relevant_price][:basis]
      s = out[:stores].first
      assert_equal true, s[:prices_disclosed]
      assert_equal 2, s[:recent_prices].size
      assert_equal "11.00", s[:recent_prices].first[:unit_price]
      assert_equal "10.00", s[:recent_prices].second[:unit_price]
    end

    test "store with one receipt stays hidden while other store with two is disclosed" do
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

      2.times do |i|
        r_b = user.receipts.create!(
          source_url: "https://example.com/b#{i}",
          status: "done",
          store_id: store_b.id,
          data_emissao: Date.current
        )
        row_b = r_b.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 20 + i,
          valor_total: 20 + i,
          product_canonical_id: pc.id
        )
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store_b.id,
          receipt_item_raw_id: row_b.id,
          observed_on: Date.current,
          quantidade: 1,
          valor_unitario: 20 + i,
          valor_total: 20 + i
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal true, out[:prices_disclosed]
      assert_equal 3, out[:receipts_distinct_count]
      assert_equal "21.00", out[:relevant_price][:unit_price]
      assert_equal store_b.id, out[:relevant_price][:store_id]

      by_nome = out[:stores].index_by { |x| x[:nome] }
      assert_equal false, by_nome["Mercado A"][:prices_disclosed]
      assert_empty by_nome["Mercado A"][:recent_prices]
      assert_equal true, by_nome["Mercado B"][:prices_disclosed]
      assert_equal 2, by_nome["Mercado B"][:recent_prices].size
    end

    test "no qualifying store: single receipt everywhere hides all prices and relevant_price" do
      user = users(:one)
      s1 = Store.create!(cnpj: "77777777000181", nome: "Só Uma Nota X")
      s2 = Store.create!(cnpj: "88888888000181", nome: "Só Uma Nota Y")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD5 #{SecureRandom.hex(4)}", display_name: "Produto só avulsos")

      [ s1, s2 ].each do |store|
        r = user.receipts.create!(
          source_url: "https://example.com/solo-#{store.id}",
          status: "done",
          store_id: store.id,
          data_emissao: Date.current
        )
        row = r.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 3,
          valor_total: 3,
          product_canonical_id: pc.id
        )
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: Date.current,
          quantidade: 1,
          valor_unitario: 3,
          valor_total: 3
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal false, out[:prices_disclosed]
      assert_nil out[:relevant_price]
      assert_equal 2, out[:observations_count]
      assert_equal 2, out[:receipts_distinct_count]
      out[:stores].each do |st|
        assert_equal false, st[:prices_disclosed]
        assert_empty st[:recent_prices]
        assert_equal 1, st[:receipts_distinct_at_store]
      end
    end

    test "two lines same product on one receipt still counts as one note at store" do
      user = users(:one)
      store = Store.create!(cnpj: "99999999000181", nome: "Duas Linhas Mesma Nota")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD6 #{SecureRandom.hex(4)}", display_name: "Produto duplicado na NFC-e")
      r = user.receipts.create!(
        source_url: "https://example.com/double-line",
        status: "done",
        store_id: store.id,
        data_emissao: Date.current
      )
      2.times do |i|
        row = r.receipt_item_raws.create!(
          descricao_bruta: "Item #{i}",
          ordem: i,
          quantidade: 1,
          valor_unitario: 10,
          valor_total: 10,
          product_canonical_id: pc.id
        )
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: Date.current,
          quantidade: 1,
          valor_unitario: 10,
          valor_total: 10
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal false, out[:prices_disclosed]
      assert_nil out[:relevant_price]
      s = out[:stores].first
      assert_equal 2, s[:observations_count]
      assert_equal 1, s[:receipts_distinct_at_store]
      assert_empty s[:recent_prices]
    end

    test "receipt outside 30-day window does not count toward per-store threshold" do
      user = users(:one)
      store = Store.create!(cnpj: "88888888000181", nome: "Janela 30d")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD7 #{SecureRandom.hex(4)}", display_name: "Fora da janela")

      [ Date.current - 40, Date.current - 1 ].each_with_index do |observed_on, i|
        receipt = user.receipts.create!(
          source_url: "https://example.com/window#{i}",
          status: "done",
          store_id: store.id,
          data_emissao: observed_on
        )
        row = receipt.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 10 + i,
          valor_total: 10 + i,
          product_canonical_id: pc.id
        )
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: observed_on,
          quantidade: 1,
          valor_unitario: 10 + i,
          valor_total: 10 + i
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal false, out[:prices_disclosed]
      assert_nil out[:relevant_price]
      s = out[:stores].first
      assert_equal 1, s[:receipts_distinct_at_store]
      assert_empty s[:recent_prices]
    end

    test "caps recent_prices at three per store" do
      user = users(:one)
      store = Store.create!(cnpj: "66666666000181", nome: "Loja D")
      pc = ProductCanonical.create!(normalized_key: "TEST PROD4 #{SecureRandom.hex(4)}", display_name: "Produto cap")

      4.times do |i|
        receipt = user.receipts.create!(
          source_url: "https://example.com/c#{i}",
          status: "done",
          store_id: store.id,
          data_emissao: Date.current
        )
        row = receipt.receipt_item_raws.create!(
          descricao_bruta: "Item",
          ordem: 0,
          quantidade: 1,
          valor_unitario: 1 + i,
          valor_total: 1 + i,
          product_canonical_id: pc.id
        )
        ObservedPrice.create!(
          product_canonical_id: pc.id,
          store_id: store.id,
          receipt_item_raw_id: row.id,
          observed_on: Date.current,
          quantidade: 1,
          valor_unitario: 1 + i,
          valor_total: 1 + i
        )
      end

      out = ProductPricesSummary.call(product_canonical_id: pc.id)
      assert_equal 3, out[:stores].first[:recent_prices].size
      assert_equal "4.00", out[:stores].first[:recent_prices].first[:unit_price]
    end
  end
end
