# frozen_string_literal: true

class StoreReconciliationRule < ApplicationRecord
  # Associations
  belongs_to :store
  belongs_to :reconciliation_rule

  # Validations
  validates :priority, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 100
  }
  validates :tolerance_value, numericality: {
    greater_than_or_equal_to: 0
  }
  validates :store_id, uniqueness: {
    scope: :reconciliation_rule_id,
    message: 'ya tiene configuración para esta regla'
  }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(:priority) }
  scope :customized, -> { where(customized: true) }
  scope :using_defaults, -> { where(customized: false) }
end
