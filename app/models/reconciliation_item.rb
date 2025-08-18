# frozen_string_literal: true

class ReconciliationItem < ApplicationRecord
  # Associations
  belongs_to :reconciliation
  belongs_to :source, polymorphic: true
  belongs_to :target, polymorphic: true

  # Enumerations
  enum :match_status, {
    matched: 'matched',
    unmatched: 'unmatched',
    partial: 'partial',
    disputed: 'disputed',
    pending_review: 'pending_review'
  }

  # Validations
  validates :match_status, presence: true

  # Scopes
  scope :manual_overrides, -> { where(manual_override: true) }
  scope :automatic_matches, -> { where(manual_override: false) }

  def has_discrepancy?
    amount_difference != 0 if amount_difference
  end
end
