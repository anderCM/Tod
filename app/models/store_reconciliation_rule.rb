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
  validates :priority, uniqueness: {
    scope: :store_id,
    message: 'ya existe otra regla con esta prioridad para la tienda'
  }
  validates :tolerance_value, numericality: {
    greater_than_or_equal_to: 0
  }
  validates :store_id, uniqueness: {
    scope: :reconciliation_rule_id,
    message: 'ya tiene configuración para esta regla'
  }
  validate :validate_tolerance_value_by_type

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(:priority) }

  private

  def validate_tolerance_value_by_type
    case reconciliation_rule.rule_type
    when 'date'
      errors.add(:tolerance_value, 'debe ser entre 0 y 31 días') if tolerance_value > 31
    when 'percentage'
      errors.add(:tolerance_value, 'debe ser entre 0 y 100%') if tolerance_value > 100
    when 'exact'
      errors.add(:tolerance_value, 'debe ser 0 para match exacto') if tolerance_value != 0
    end
  end
end
