# frozen_string_literal: true

class StoreSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :status, :tax_id, :phone, :address, :description
end
