class CreateReconciliationItems < ActiveRecord::Migration[8.0]
  def change
    create_table :reconciliation_items do |t|
      t.references :reconciliation, null: false, foreign_key: true

      t.string :source_type
      t.bigint :source_id

      t.string :target_type
      t.bigint :target_id

      t.string :match_status, null: false, default: 'unmatched'
      t.string :match_rule_applied
      t.decimal :amount_difference, precision: 10, scale: 2, default: 0
      t.integer :date_difference_days
      t.boolean :manual_override, default: false
      t.text :notes

      t.timestamps
    end

    add_index :reconciliation_items, [:source_type, :source_id]
    add_index :reconciliation_items, [:target_type, :target_id]
    add_index :reconciliation_items, :match_status
    add_index :reconciliation_items, [:reconciliation_id, :match_status]
  end
end