# frozen_string_literal: true

class AddDeviseToStores < ActiveRecord::Migration[8.0]
  def self.up
    change_table :stores do |t|
      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## API Authentication
      t.string :authentication_token

      ## Trackable
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps null: false
    end

    add_index :stores, :email,                unique: true
    add_index :stores, :reset_password_token, unique: true
    add_index :stores, :authentication_token, unique: true
    # add_index :stores, :confirmation_token,   unique: true
    # add_index :stores, :unlock_token,         unique: true
  end

  def self.down
    change_table :stores do |t|
      t.remove :encrypted_password if column_exists?(:stores, :encrypted_password)
      t.remove :reset_password_token if column_exists?(:stores, :reset_password_token)
      t.remove :reset_password_sent_at if column_exists?(:stores, :reset_password_sent_at)
      t.remove :remember_created_at if column_exists?(:stores, :remember_created_at)
      t.remove :authentication_token if column_exists?(:stores, :authentication_token)
    end

    remove_index :stores, :email if index_exists?(:stores, :email)
    remove_index :stores, :reset_password_token if index_exists?(:stores, :reset_password_token)
    remove_index :stores, :authentication_token if index_exists?(:stores, :authentication_token)
  end
end
