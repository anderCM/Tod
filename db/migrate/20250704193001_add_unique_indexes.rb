class AddUniqueIndexes < ActiveRecord::Migration[8.0]
  def change
    # Índice único para email de customers
    add_index :customers, :email, unique: true
    
    # Índice único para document_number de customers
    add_index :customers, :document_number, unique: true
    
    # Índice único para tax_id de stores
    add_index :stores, :tax_id, unique: true
    
    # Índice único para reference de transactions
    add_index :transactions, :reference, unique: true
  end
end 