# frozen_string_literal: true

class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table(:wallets) do |t|
      t.decimal(:balance)
      t.references(:owner, polymorphic: true, null: false)
      t.string(:wallet_type)
      t.string(:status)

      t.timestamps
    end
  end
end
