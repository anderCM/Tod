# frozen_string_literal: true

class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :amount, :transaction_type, :description, :reference, :status, :transaction_date
end