# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table(:transactions) do |t|
      t.decimal(:amount)
      t.string(:transaction_type)
      t.text(:description)
      t.string(:reference)
      t.string(:status)
      t.references(:wallet, null: false, foreign_key: true)
      t.references(:store, null: false, foreign_key: true)
      t.references(:customer, null: false, foreign_key: true)

      t.timestamps
    end
  end
end
