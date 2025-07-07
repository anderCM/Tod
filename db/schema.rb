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

ActiveRecord::Schema[8.0].define(version: 2025_07_07_193738) do
  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "document_number"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_number"], name: "index_customers_on_document_number", unique: true
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.integer "store_id", null: false
    t.integer "customer_id", null: false
    t.string "sale_number", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "sale_date", null: false
    t.string "status", default: "pending", null: false
    t.text "description"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["sale_date"], name: "index_sales_on_sale_date"
    t.index ["sale_number"], name: "index_sales_on_sale_number", unique: true
    t.index ["status"], name: "index_sales_on_status"
    t.index ["store_id"], name: "index_sales_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "status"
    t.string "tax_id"
    t.text "address"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_id"], name: "index_stores_on_tax_id", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount"
    t.string "transaction_type"
    t.text "description"
    t.string "reference"
    t.string "status"
    t.integer "wallet_id", null: false
    t.integer "store_id", null: false
    t.integer "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "transaction_date"
    t.index ["customer_id"], name: "index_transactions_on_customer_id"
    t.index ["reference"], name: "index_transactions_on_reference", unique: true
    t.index ["store_id"], name: "index_transactions_on_store_id"
    t.index ["wallet_id"], name: "index_transactions_on_wallet_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.decimal "balance"
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "wallet_type"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_wallets_on_owner"
  end

  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "stores"
  add_foreign_key "transactions", "customers"
  add_foreign_key "transactions", "stores"
  add_foreign_key "transactions", "wallets"
end
