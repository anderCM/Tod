class CreateReconciliations < ActiveRecord::Migration[8.0]
  def change
    create_table :reconciliations do |t|
      t.references :store, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :status, null: false, default: 'pending'
      t.string :reconciliation_type, null: false, default: 'automatic'
      t.integer :total_matched, null: false, default: 0
      t.integer :total_unmatched, null: false, default: 0
      t.decimal :total_amount_matched, precision: 10, scale: 2, default: 0
      t.decimal :total_amount_unmatched, precision: 10, scale: 2, default: 0
      t.string :initiated_by, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :reconciliations, :status
    add_index :reconciliations, [:store_id, :start_date, :end_date]
  end
end