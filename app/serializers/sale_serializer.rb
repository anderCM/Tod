# frozen_string_literal: true

class SaleSerializer < ActiveModel::Serializer
  attributes :id, :sale_number, :total_amount, :sale_date, :status, :description, :metadata
end