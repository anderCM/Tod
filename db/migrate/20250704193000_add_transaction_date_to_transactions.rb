# frozen_string_literal: true

class AddTransactionDateToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column(:transactions, :transaction_date, :datetime)
  end
end
