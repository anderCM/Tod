class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :store, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :sale_number, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.datetime :sale_date, null: false
      t.string :status, null: false, default: 'pending'
      t.text :description
      t.json :metadata

      t.timestamps
    end

    add_index :sales, :sale_number, unique: true
    add_index :sales, :sale_date
    add_index :sales, :status
  end
end
