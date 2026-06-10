# frozen_string_literal: true

# Histórico de preços em Erechim/RS: 3 mercados, 5 produtos, 2 notas por mercado.
# Rodar: bin/rails db:seed  ou  bin/rails runner "Seeds::ErechimMarketHistory.run!(force: true)"
module Seeds
  module ErechimMarketHistory
    SOURCE_PREFIX = "https://carrinho-certo.local/erechim/nota"
    LIST_NAME = "Compras Erechim"
    CITY = "Erechim"
    UF = "RS"

    PRODUCTS = [
      { key: "COCA COLA PET 2L", name: "Coca-Cola Pet 2L", desc: "REFRIG COCA COLA PET 2L" },
      { key: "COCA COLA PET 1L", name: "Coca-Cola Pet 1L", desc: "REFRIG COCA COLA PET 1L" },
      { key: "SORVETE KIBON 1 5KG", name: "Sorvete Kibon 1,5kg", desc: "SORVETE KIBON 1.5KG CREME" },
      { key: "LEITE INTEGRAL TIROL 1L", name: "Leite Integral Tirol 1L", desc: "LEITE INTEGRAL TIROL 1L" },
      { key: "ARROZ TIO JOAO 5KG", name: "Arroz Tio João 5kg", desc: "ARROZ TIO JOAO TP1 5KG" }
    ].freeze

    # Mercados de Erechim (CNPJs fictícios exceto Master ATS, comum na região)
    STORES = [
      {
        cnpj: "02471822000158",
        nome: "Koch Hipermercado Erechim",
        endereco: "Av. Maurício Cardoso, 1600"
      },
      {
        cnpj: "92717589000120",
        nome: "Brizolla Supermercados",
        endereco: "R. Benjamin Constant, 801"
      },
      {
        cnpj: "01874166000280",
        nome: "Master ATS Supermercados",
        endereco: "Av. Sete de Setembro, 1200"
      }
    ].freeze

    # Preço atual (nota mais recente) por produto, mesma ordem de PRODUCTS
    CURRENT_PRICES = {
      "02471822000158" => [7.49, 4.99, 32.50, 4.49, 26.99],
      "92717589000120" => [8.99, 5.49, 34.90, 4.99, 28.90],
      "01874166000280" => [8.49, 5.29, 33.99, 4.79, 27.50]
    }.freeze

    mattr_accessor :product_ids, :store_ids

    module_function

    def run!(force: false)
      if !force && sample_receipts.exists?
        return puts("Seeds::ErechimMarketHistory: já existe (use force: true para recriar)")
      end

      cleanup! if force

      user = User.order(:id).first
      unless user
        puts "Seeds::ErechimMarketHistory: crie uma conta no app e rode o seed de novo."
        return
      end

      products = PRODUCTS.map do |p|
        ProductCanonical.find_or_create_by!(normalized_key: p[:key]) do |pc|
          pc.display_name = p[:name]
        end
      end

      stores = STORES.map do |s|
        store = Store.find_or_create_by!(cnpj: s[:cnpj])
        store.update!(nome: s[:nome], cidade: CITY, uf: UF, endereco: s[:endereco])
        store
      end

      self.product_ids = products.map(&:id)
      self.store_ids = stores.map(&:id)
      @chave_seq = Receipt.where("chave_acesso LIKE ?", "88%").count

      stores.each_with_index do |store, store_idx|
        current = CURRENT_PRICES.fetch(store.cnpj)
        older = current.map { |p| (p * BigDecimal("1.08")).round(2) }

        add_store_receipt!(
          user: user, store: store, products: products,
          prices: older, observed_on: Date.current - 14 - store_idx, seq: (store_idx * 2) + 1
        )
        add_store_receipt!(
          user: user, store: store, products: products,
          prices: current, observed_on: Date.current - 2 + store_idx, seq: (store_idx * 2) + 2
        )
      end

      User.find_each { |u| ensure_comparison_list!(user: u, products: products) }

      puts "Seeds::ErechimMarketHistory: OK"
      puts "  #{stores.size} mercados em #{CITY}/#{UF}, #{products.size} produtos, #{sample_receipts.count} notas"
      puts "  Lista: '#{LIST_NAME}' (#{products.size} itens)"
    end

    def ensure_comparison_list!(user:, products:)
      list = user.shopping_lists.find_or_initialize_by(name: LIST_NAME)
      list.save! if list.new_record?
      list.shopping_list_items.destroy_all

      products.each_with_index do |product, idx|
        list.shopping_list_items.create!(
          product_canonical_id: product.id,
          label: product.display_name,
          quantidade: 1,
          ordem: idx
        )
      end
    end

    def cleanup!
      sample_receipts.destroy_all
      purge_non_seed_receipts!
      purge_non_erechim_stores!
      purge_legacy_demo_data!
      purge_fixture_products!
    end

    def purge_non_seed_receipts!
      Receipt.where.not("source_url LIKE ?", "#{SOURCE_PREFIX}/%").destroy_all
    end

    def purge_non_erechim_stores!
      seed_cnpjs = STORES.map { |s| s[:cnpj] }
      orphan_ids = Store.where.not(cnpj: seed_cnpjs).pluck(:id)
      purge_stores!(orphan_ids)
    end

    def purge_legacy_demo_data!
      legacy_prefixes = [
        "https://seed.demo/pricing",
        "https://carrinho-certo.local/nota"
      ]
      legacy_prefixes.each do |prefix|
        Receipt.where("source_url LIKE ?", "#{prefix}%").destroy_all
      end

      legacy_cnpjs = %w[99000001000109 99000002000180 99000003000160]
      legacy_store_ids = Store.where(cnpj: legacy_cnpjs).pluck(:id)
      purge_stores!(legacy_store_ids)

      legacy_keys = %w[SEED_DEMO_ARROZ_5KG SEED_DEMO_OLEO_900ML]
      purge_products!(legacy_keys)

      User.where(email: %w[seed-pricing@example.local dados@carrinho-certo.local]).delete_all
      ShoppingList.where(name: "Lista teste comparativo").destroy_all
    end

    def purge_fixture_products!
      purge_products!(["ARROZ 5KG FIX ONE", "FEIJAO 1KG FIX TWO", "ARROZ 5KG TEST", "FEIJAO 1KG TEST"])
    end

    def purge_stores!(store_ids)
      return if store_ids.empty?

      ObservedPrice.where(store_id: store_ids).delete_all
      Receipt.where(store_id: store_ids).destroy_all
      Store.where(id: store_ids).delete_all
    end

    def purge_products!(normalized_keys)
      ids = ProductCanonical.where(normalized_key: normalized_keys).pluck(:id)
      return if ids.empty?

      ShoppingListItem.where(product_canonical_id: ids).update_all(product_canonical_id: nil)
      ObservedPrice.where(product_canonical_id: ids).delete_all
      ProductCanonical.where(id: ids).delete_all
    end

    def sample_receipts
      Receipt.where("source_url LIKE ?", "#{SOURCE_PREFIX}/%")
    end

    def add_store_receipt!(user:, store:, products:, prices:, observed_on:, seq:)
      receipt_total = prices.sum + BigDecimal("12.50")
      receipt = create_receipt!(
        user: user, store: store, observed_on: observed_on,
        receipt_total: receipt_total, seq: seq
      )

      products.each_with_index do |product, i|
        unit = prices[i]
        add_line!(
          receipt: receipt, product: product, desc: PRODUCTS[i][:desc],
          observed_on: observed_on, quantidade: 1, unidade: "UN",
          valor_unitario: unit, valor_total: unit
        )
      end
    end

    def create_receipt!(user:, store:, observed_on:, receipt_total:, seq:)
      @chave_seq += 1
      user.receipts.create!(
        source_url: "#{SOURCE_PREFIX}/#{store.cnpj}/#{seq}",
        status: "done",
        store_id: store.id,
        data_emissao: observed_on,
        hora_emissao: "14:30:00",
        chave_acesso: format_chave(@chave_seq),
        numero: format("%06d", seq),
        serie: "1",
        valor_total: receipt_total,
        processed_at: Time.current
      )
    end

    def add_line!(receipt:, product:, desc:, observed_on:, quantidade:, unidade:, valor_unitario:, valor_total:)
      line = receipt.receipt_item_raws.create!(
        descricao_bruta: desc,
        ordem: receipt.receipt_item_raws.count,
        quantidade: quantidade,
        unidade: unidade,
        valor_unitario: valor_unitario,
        valor_total: valor_total,
        product_canonical_id: product.id,
        normalization_source: "receipt"
      )
      ObservedPrice.create!(
        product_canonical_id: product.id,
        store_id: receipt.store_id,
        receipt_item_raw_id: line.id,
        observed_on: observed_on,
        quantidade: quantidade,
        unidade: unidade,
        valor_unitario: valor_unitario,
        valor_total: valor_total
      )
    end

    def format_chave(seq)
      format("88%042d", seq)[0, 44]
    end
  end
end
