# frozen_string_literal: true

class WalletSerializer < ActiveModel::Serializer
  attributes :id, :balance
end
