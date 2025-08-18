class CreateStoreReconciliationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :store_reconciliation_rules do |t|
      t.references :store, null: false, foreign_key: true
      t.references :reconciliation_rule, null: false, foreign_key: true

      t.decimal :tolerance_value, precision: 10, scale: 2, null: false
      t.integer :priority, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :store_reconciliation_rules,
      [:store_id, :reconciliation_rule_id],
      unique: true,
      name: 'idx_store_recon_rules_unique'
    add_index :store_reconciliation_rules,
      [:store_id, :active, :priority],
      name: 'idx_store_recon_rules_lookup'
  end
end
