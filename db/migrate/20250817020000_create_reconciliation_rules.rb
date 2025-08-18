class CreateReconciliationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :reconciliation_rules do |t|
      t.string :rule_type, null: false
      t.decimal :default_tolerance_value, precision: 10, scale: 2, default: 0
      t.string :name, null: false
      t.text :description
      t.integer :priority, null: false, default: 1
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :reconciliation_rules, :rule_type, unique: true
    add_index :reconciliation_rules, :priority
    add_index :reconciliation_rules, :active
  end
end
