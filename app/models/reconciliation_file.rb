# frozen_string_literal: true

class ReconciliationFile < ApplicationRecord
  # Associations
  belongs_to :reconciliation
  has_one_attached :file

  # Enumerations
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  enum :file_type, {
    csv: 'csv',
    excel: 'excel',
    txt: 'txt'
  }

  # Validations
  validates :file_name, presence: true
  validates :file_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }
end
