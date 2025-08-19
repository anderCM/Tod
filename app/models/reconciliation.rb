# frozen_string_literal: true

class Reconciliation < ApplicationRecord
  # Associations
  belongs_to :store
  has_many :reconciliation_items, dependent: :destroy
  has_many :reconciliation_files, dependent: :destroy
  has_many :matched_items,
    -> { where(match_status: 'matched') },
    class_name: 'ReconciliationItem'
  has_many :unmatched_items,
    -> { where(match_status: 'unmatched') },
    class_name: 'ReconciliationItem'

  # Enumerations
  enum :status, {
    pending: 'pending',
    in_progress: 'in_progress',
    completed: 'completed',
    failed: 'failed',
    with_errors: 'with_errors'
  }

  enum :reconciliation_type, {
    automatic: 'automatic',
    manual: 'manual',
    mixed: 'mixed',
    file_import: 'file_import'
  }

  enum :initiated_by, {
    store_user: 'store_user',
    admin: 'admin',
    system: 'system'
  }

  # Validations
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_period, ->(start_date, end_date) {
    where('start_date >= ? AND end_date <= ?', start_date, end_date)
  }

  def date_range
    start_date..end_date
  end

  def duration_in_days
    (end_date - start_date).to_i + 1
  end

  def can_be_modified?
    pending? || failed?
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after or equal to start date') if end_date < start_date
  end
end
