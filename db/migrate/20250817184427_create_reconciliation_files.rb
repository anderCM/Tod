class CreateReconciliationFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :reconciliation_files do |t|
      t.references :reconciliation, foreign_key: true, null: false

      t.string :file_name, null: false
      t.string :file_type, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
    add_index :reconciliation_files, :status
  end
end
