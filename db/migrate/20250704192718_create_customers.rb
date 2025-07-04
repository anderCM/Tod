# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table(:customers) do |t|
      t.string(:name)
      t.string(:email)
      t.string(:phone)
      t.string(:document_number)
      t.string(:status)

      t.timestamps
    end
  end
end
