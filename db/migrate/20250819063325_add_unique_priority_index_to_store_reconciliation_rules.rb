class AddUniquePriorityIndexToStoreReconciliationRules < ActiveRecord::Migration[8.0]
  def change
    add_index :store_reconciliation_rules, 
              [:store_id, :priority], 
              unique: true,
              name: 'idx_store_priority_unique'
  end
end
