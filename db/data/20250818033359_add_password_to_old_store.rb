# frozen_string_literal: true

class AddPasswordToOldStore < ActiveRecord::Migration[8.0]
  def up
    # We don't need to use batch processing here because
    # there are not a lot of stores.

    default_password = 'Conectado$25'
    Store.all.each do |store|
      store.password = default_password
      store.password_confirmation = default_password
      store.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
