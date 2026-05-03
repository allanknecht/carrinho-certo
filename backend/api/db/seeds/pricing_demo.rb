# frozen_string_literal: true

# Cenários para GET /products/:id/prices: último preço por loja (data de emissão da NFC-e).
# Rodar: bin/rails db:seed (em development) ou: bin/rails runner "Seeds::PricingDemo.run!"
#
module Seeds
  module PricingDemo
    USER_EMAIL = "seed-pricing@example.local"
    USER_PASSWORD = "seedpricing123"
    SOURCE_PREFIX = "https://seed.demo/pricing"

    mattr_accessor :product_alpha_id, :product_beta_id, :user_email

    module_function

    def run!(force: false)
      self.user_email = USER_EMAIL
      @chave_seq = 0
      cleanup! if force || demo_receipts.exists? || demo_products.exists?

      user = User.find_or_initialize_by(email: USER_EMAIL)
      user.password = USER_PASSWORD
      user.password_confirmation = USER_PASSWORD
      user.save!

      stores = {
        one: Store.create!(cnpj: "99000001000109", nome: "Mercado Uma Nota (demo)"),
        two: Store.create!(cnpj: "99000002000180", nome: "Mercado Duas Notas (demo)"),
        three: Store.create!(cnpj: "99000003000160", nome: "Mercado Três Notas (demo)")
      }

      alpha = ProductCanonical.create!(
        normalized_key: "SEED_DEMO_ARROZ_5KG",
        display_name: "Arroz demo 5kg"
      )
      beta = ProductCanonical.create!(
        normalized_key: "SEED_DEMO_OLEO_900ML",
        display_name: "Óleo demo 900ml"
      )
      self.product_alpha_id = alpha.id
      self.product_beta_id = beta.id

      # --- Produto Alpha ---
      # Loja "uma nota": 1 NFC-e → preço visível (última por loja)
      add_observation!(
        user: user,
        store: stores[:one],
        product: alpha,
        desc: "ARROZ DEMO 5KG",
        observed_on: Date.current - 5,
        receipt_total: BigDecimal("50.00"),
        quantidade: 2,
        unidade: "UN",
        valor_unitario: BigDecimal("10.00"),
        valor_total: BigDecimal("20.00")
      )

      # Loja "duas notas": 2 NFC-e → última emissão vence
      add_observation!(
        user: user,
        store: stores[:two],
        product: alpha,
        desc: "ARROZ DEMO 5KG",
        observed_on: Date.current - 4,
        receipt_total: BigDecimal("45.00"),
        quantidade: 1,
        unidade: "UN",
        valor_unitario: BigDecimal("15.00"),
        valor_total: BigDecimal("15.00")
      )
      add_observation!(
        user: user,
        store: stores[:two],
        product: alpha,
        desc: "ARROZ DEMO 5KG",
        observed_on: Date.current - 1,
        receipt_total: BigDecimal("48.00"),
        quantidade: 1,
        unidade: "UN",
        valor_unitario: BigDecimal("18.00"),
        valor_total: BigDecimal("18.00")
      )

      # Loja "três notas": 3 NFC-e → última emissão (mais recente)
      [ BigDecimal("12.00"), BigDecimal("11.50"), BigDecimal("11.00") ].each_with_index do |unit, i|
        add_observation!(
          user: user,
          store: stores[:three],
          product: alpha,
          desc: "ARROZ DEMO 5KG",
          observed_on: Date.current - (3 - i),
          receipt_total: BigDecimal("40.00") + i,
          quantidade: 1,
          unidade: "UN",
          valor_unitario: unit,
          valor_total: unit
        )
      end

      # --- Produto Beta ---
      # Mesma loja "uma nota": 1 nota com Beta
      add_observation!(
        user: user,
        store: stores[:one],
        product: beta,
        desc: "OLEO DEMO 900ML",
        observed_on: Date.current - 2,
        receipt_total: BigDecimal("30.00"),
        quantidade: 1,
        unidade: "UN",
        valor_unitario: BigDecimal("8.00"),
        valor_total: BigDecimal("8.00")
      )

      # Loja "duas notas": 2 notas com Beta → última emissão
      add_observation!(
        user: user,
        store: stores[:two],
        product: beta,
        desc: "OLEO DEMO 900ML",
        observed_on: Date.current - 3,
        receipt_total: BigDecimal("35.00"),
        quantidade: 2,
        unidade: "UN",
        valor_unitario: BigDecimal("7.50"),
        valor_total: BigDecimal("15.00")
      )
      add_observation!(
        user: user,
        store: stores[:two],
        product: beta,
        desc: "OLEO DEMO 900ML",
        observed_on: Date.current - 1,
        receipt_total: BigDecimal("36.00"),
        quantidade: 1,
        unidade: "UN",
        valor_unitario: BigDecimal("9.00"),
        valor_total: BigDecimal("9.00")
      )

      puts "Seeds::PricingDemo: OK"
      puts "  user: #{USER_EMAIL} / #{USER_PASSWORD}"
      puts "  product_alpha_id=#{alpha.id} (Arroz)  product_beta_id=#{beta.id} (Óleo)"
      puts "  Teste preços: bin/rails runner script/product_prices_smoke.rb #{alpha.id}"
    end

    def cleanup!
      demo_receipts.destroy_all

      Store.where(cnpj: %w[99000001000109 99000002000180 99000003000160]).delete_all
      ShoppingListItem.where(product_canonical_id: demo_products.select(:id)).update_all(product_canonical_id: nil)
      demo_products.delete_all
      User.where(email: USER_EMAIL).delete_all
    end

    def demo_receipts
      Receipt.where("source_url LIKE ?", "#{SOURCE_PREFIX}/%")
    end

    def demo_products
      ProductCanonical.where(normalized_key: %w[SEED_DEMO_ARROZ_5KG SEED_DEMO_OLEO_900ML])
    end

    def add_observation!(user:, store:, product:, desc:, observed_on:, receipt_total:, quantidade:, unidade:,
      valor_unitario:, valor_total:)
      @chave_seq += 1
      chave = format_chave(@chave_seq)
      receipt = user.receipts.create!(
        source_url: "#{SOURCE_PREFIX}/r#{@chave_seq}",
        status: "done",
        store_id: store.id,
        data_emissao: observed_on,
        chave_acesso: chave,
        valor_total: receipt_total,
        processed_at: Time.current
      )
      line = receipt.receipt_item_raws.create!(
        descricao_bruta: desc,
        ordem: 0,
        quantidade: quantidade,
        unidade: unidade,
        valor_unitario: valor_unitario,
        valor_total: valor_total,
        product_canonical_id: product.id,
        normalization_source: "seed"
      )
      ObservedPrice.create!(
        product_canonical_id: product.id,
        store_id: store.id,
        receipt_item_raw_id: line.id,
        observed_on: observed_on,
        quantidade: quantidade,
        unidade: unidade,
        valor_unitario: valor_unitario,
        valor_total: valor_total
      )
    end

    def format_chave(seq)
      # 44 dígitos únicos para índice parcial em receipts.chave_acesso
      s = "99#{format('%042d', seq)}"
      s[-44, 44]
    end
  end
end
