# frozen_string_literal: true

class ReconciliationRule < ApplicationRecord
  # Associations
  has_many :store_reconciliation_rules, dependent: :destroy
  has_many :stores, through: :store_reconciliation_rules

  # Enums
  enum :rule_type, {
    exact: 'exact',
    date: 'date',
    percentage: 'percentage',
    amount: 'amount'
  }

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :rule_type, presence: true, uniqueness: true
  validates :priority, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 100
  }
  validates :default_tolerance_value, numericality: {
    greater_than_or_equal_to: 0
  }
  validate :validate_tolerance_value_by_type

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(:priority) }

  private

  def validate_tolerance_value_by_type
    case rule_type
    when 'date'
      errors.add(:default_tolerance_value, 'debe ser entre 0 y 31 días') if default_tolerance_value > 31
    when 'percentage'
      errors.add(:default_tolerance_value, 'debe ser entre 0 y 100%') if default_tolerance_value > 100
    when 'exact'
      errors.add(:default_tolerance_value, 'debe ser 0 para match exacto') if default_tolerance_value != 0
    end
  end
end
