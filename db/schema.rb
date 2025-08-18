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

ActiveRecord::Schema[8.0].define(version: 2025_08_17_190244) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "reconciliation_files", force: :cascade do |t|
    t.bigint "reconciliation_id", null: false
    t.string "file_name", null: false
    t.string "file_type", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reconciliation_id"], name: "index_reconciliation_files_on_reconciliation_id"
    t.index ["status"], name: "index_reconciliation_files_on_status"
  end

  create_table "reconciliation_items", force: :cascade do |t|
    t.bigint "reconciliation_id", null: false
    t.string "source_type"
    t.bigint "source_id"
    t.string "target_type"
    t.bigint "target_id"
    t.string "match_status", default: "unmatched", null: false
    t.string "match_rule_applied"
    t.decimal "amount_difference", precision: 10, scale: 2, default: "0.0"
    t.integer "date_difference_days"
    t.boolean "manual_override", default: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_status"], name: "index_reconciliation_items_on_match_status"
    t.index ["reconciliation_id", "match_status"], name: "idx_on_reconciliation_id_match_status_84941c32a3"
    t.index ["reconciliation_id"], name: "index_reconciliation_items_on_reconciliation_id"
    t.index ["source_type", "source_id"], name: "index_reconciliation_items_on_source_type_and_source_id"
    t.index ["target_type", "target_id"], name: "index_reconciliation_items_on_target_type_and_target_id"
  end

  create_table "reconciliation_rules", force: :cascade do |t|
    t.string "rule_type", null: false
    t.decimal "default_tolerance_value", precision: 10, scale: 2, default: "0.0"
    t.string "name", null: false
    t.text "description"
    t.integer "priority", default: 1, null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_reconciliation_rules_on_active"
    t.index ["priority"], name: "index_reconciliation_rules_on_priority"
    t.index ["rule_type"], name: "index_reconciliation_rules_on_rule_type", unique: true
  end

  create_table "reconciliations", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "status", default: "pending", null: false
    t.string "reconciliation_type", default: "automatic", null: false
    t.integer "total_matched", default: 0, null: false
    t.integer "total_unmatched", default: 0, null: false
    t.decimal "total_amount_matched", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount_unmatched", precision: 10, scale: 2, default: "0.0"
    t.string "initiated_by", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_reconciliations_on_status"
    t.index ["store_id", "start_date", "end_date"], name: "index_reconciliations_on_store_id_and_start_date_and_end_date"
    t.index ["store_id"], name: "index_reconciliations_on_store_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "customer_id", null: false
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

  create_table "store_reconciliation_rules", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "reconciliation_rule_id", null: false
    t.decimal "tolerance_value", precision: 10, scale: 2, null: false
    t.integer "priority", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reconciliation_rule_id"], name: "index_store_reconciliation_rules_on_reconciliation_rule_id"
    t.index ["store_id", "active", "priority"], name: "idx_store_recon_rules_lookup"
    t.index ["store_id", "reconciliation_rule_id"], name: "idx_store_recon_rules_unique", unique: true
    t.index ["store_id"], name: "index_store_reconciliation_rules_on_store_id"
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
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "authentication_token"
    t.index ["authentication_token"], name: "index_stores_on_authentication_token", unique: true
    t.index ["email"], name: "index_stores_on_email", unique: true
    t.index ["reset_password_token"], name: "index_stores_on_reset_password_token", unique: true
    t.index ["tax_id"], name: "index_stores_on_tax_id", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount"
    t.string "transaction_type"
    t.text "description"
    t.string "reference"
    t.string "status"
    t.bigint "wallet_id", null: false
    t.bigint "store_id", null: false
    t.bigint "customer_id", null: false
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
    t.bigint "owner_id", null: false
    t.string "wallet_type"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_wallets_on_owner"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "reconciliation_files", "reconciliations"
  add_foreign_key "reconciliation_items", "reconciliations"
  add_foreign_key "reconciliations", "stores"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "stores"
  add_foreign_key "store_reconciliation_rules", "reconciliation_rules"
  add_foreign_key "store_reconciliation_rules", "stores"
  add_foreign_key "transactions", "customers"
  add_foreign_key "transactions", "stores"
  add_foreign_key "transactions", "wallets"
end
