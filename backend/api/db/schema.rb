# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_11_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "observed_prices", force: :cascade do |t|
    t.bigint "product_canonical_id", null: false
    t.bigint "store_id"
    t.bigint "receipt_item_raw_id", null: false
    t.date "observed_on", null: false
    t.decimal "quantidade", precision: 12, scale: 3
    t.decimal "valor_unitario", precision: 12, scale: 4
    t.decimal "valor_total", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unidade", limit: 10
    t.index ["product_canonical_id", "observed_on"], name: "index_observed_prices_on_product_canonical_and_observed_on"
    t.index ["product_canonical_id"], name: "index_observed_prices_on_product_canonical_id"
    t.index ["receipt_item_raw_id"], name: "index_observed_prices_on_receipt_item_raw_id", unique: true
    t.index ["store_id"], name: "index_observed_prices_on_store_id"
  end

  create_table "product_aliases", force: :cascade do |t|
    t.bigint "product_canonical_id", null: false
    t.string "alias_normalized", null: false
    t.string "source", default: "manual", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alias_normalized"], name: "index_product_aliases_on_alias_normalized", unique: true
    t.index ["product_canonical_id"], name: "index_product_aliases_on_product_canonical_id"
  end

  create_table "products_canonical", force: :cascade do |t|
    t.string "display_name", null: false
    t.string "normalized_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_key"], name: "index_products_canonical_on_normalized_key", unique: true
  end

  create_table "receipt_items_raw", force: :cascade do |t|
    t.bigint "receipt_id", null: false
    t.text "descricao_bruta", null: false
    t.string "codigo_estabelecimento"
    t.decimal "quantidade", precision: 12, scale: 3
    t.string "unidade", limit: 10
    t.decimal "valor_unitario", precision: 12, scale: 4
    t.decimal "valor_total", precision: 12, scale: 2
    t.integer "ordem", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_canonical_id"
    t.string "normalization_source"
    t.index ["product_canonical_id"], name: "index_receipt_items_raw_on_product_canonical_id"
    t.index ["receipt_id"], name: "index_receipt_items_raw_on_receipt_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.text "source_url"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.text "processing_error"
    t.datetime "processed_at"
    t.bigint "store_id"
    t.string "chave_acesso", limit: 44
    t.string "numero"
    t.string "serie"
    t.date "data_emissao"
    t.time "hora_emissao"
    t.decimal "valor_total", precision: 12, scale: 2
    t.index ["chave_acesso"], name: "index_receipts_on_chave_acesso_unique_non_null", unique: true, where: "(chave_acesso IS NOT NULL)"
    t.index ["store_id"], name: "index_receipts_on_store_id"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_shopping_lists_on_user_id"
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.bigint "shopping_list_id", null: false
    t.bigint "product_canonical_id"
    t.string "label"
    t.decimal "quantidade", precision: 12, scale: 3, default: "1.0", null: false
    t.integer "ordem", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_canonical_id"], name: "index_shopping_list_items_on_product_canonical_id"
    t.index ["shopping_list_id", "ordem"], name: "index_shopping_list_items_on_shopping_list_id_and_ordem"
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "cnpj", null: false
    t.string "nome", null: false
    t.text "endereco"
    t.string "cidade"
    t.string "uf", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_stores_on_cnpj", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "observed_prices", "products_canonical", column: "product_canonical_id"
  add_foreign_key "observed_prices", "receipt_items_raw", column: "receipt_item_raw_id"
  add_foreign_key "observed_prices", "stores"
  add_foreign_key "product_aliases", "products_canonical", column: "product_canonical_id"
  add_foreign_key "receipt_items_raw", "products_canonical", column: "product_canonical_id"
  add_foreign_key "receipt_items_raw", "receipts"
  add_foreign_key "receipts", "stores"
  add_foreign_key "receipts", "users"
  add_foreign_key "shopping_list_items", "products_canonical", column: "product_canonical_id"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_lists", "users"
end
