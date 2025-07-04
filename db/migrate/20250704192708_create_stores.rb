# frozen_string_literal: true

class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table(:stores) do |t|
      t.string(:name)
      t.text(:description)
      t.string(:status)
      t.string(:tax_id)
      t.text(:address)
      t.string(:phone)
      t.string(:email)

      t.timestamps
    end
  end
end
