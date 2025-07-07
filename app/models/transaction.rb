# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :store
  belongs_to :customer

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: ["payment", "refund", "fee", "deposit"] }
  validates :description, presence: true, length: { minimum: 5, maximum: 500 }
  validates :reference, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: ["completed", "pending", "failed"] }
  validates :transaction_date, presence: true
  validates :wallet, presence: true
  validates :customer, presence: true
  validates :store, presence: true

  validate :amount_validation_for_refund
  validate :store_required_for_payment_and_refund

  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :by_type, ->(type) { where(transaction_type: type) }
  scope :by_store, ->(store) { where(store: store) }
  scope :by_customer, ->(customer) { where(customer: customer) }
  scope :in_period, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }
  scope :recent, -> { where("transaction_date >= ?", 30.days.ago) }

  before_validation :generate_reference, on: :create
  before_validation :set_transaction_date, on: :create

  class << self
    def total_amount_by_period(start_date, end_date, status = "completed")
      where(status: status, transaction_date: start_date..end_date).sum(:amount)
    end

    def count_by_period(start_date, end_date, status = "completed")
      where(status: status, transaction_date: start_date..end_date).count
    end

    def summary_by_period(start_date, end_date)
      transactions = where(transaction_date: start_date..end_date)

      {
        total_count: transactions.count,
        completed_count: transactions.where(status: "completed").count,
        pending_count: transactions.where(status: "pending").count,
        failed_count: transactions.where(status: "failed").count,
        total_amount: transactions.where(status: "completed").sum(:amount),
        pending_amount: transactions.where(status: "pending").sum(:amount),
        by_type: transactions.group(:transaction_type).count,
        by_status: transactions.group(:status).count,
      }
    end
  end

  def related_transactions
    related = Transaction.where(
      amount: amount,
      store: store,
      customer: customer,
      transaction_type: transaction_type,
    ).where.not(id: id)

    related.where(
      "DATE(transaction_date) = DATE(?)", transaction_date
    )
  end

  def can_be_reconciled?
    status == "completed" &&
      transaction_date.present? &&
      amount.present? &&
      reference.present?
  end

  def reconciliation_info
    {
      id: id,
      reference: reference,
      amount: amount,
      transaction_type: transaction_type,
      status: status,
      transaction_date: transaction_date,
      store_name: store.name,
      customer_name: customer.name,
      wallet_owner: wallet.owner.name,
      description: description,
      can_be_reconciled: can_be_reconciled?,
      related_transactions_count: related_transactions.count,
    }
  end

  def mark_as_reconciled!
    update!(status: "completed") if status == "pending"
  end

  private

  def generate_reference
    return if reference.present?

    prefix = case transaction_type
    when "payment" then "PAY"
    when "refund" then "REF"
    when "fee" then "FEE"
    when "deposit" then "DEP"
    else "TXN"
    end

    self.reference = "#{prefix}-#{SecureRandom.hex(6).upcase}"
  end

  def set_transaction_date
    self.transaction_date ||= Time.current
  end

  def store_required_for_payment_and_refund
    if ["payment", "refund"].include?(transaction_type) && store.blank?
      errors.add(:store, "es requerido para transacciones de pago y reembolso")
    end
  end

  def amount_validation_for_refund
    if transaction_type == "refund" && store.present?
      total_paid = Transaction.where(
        store: store,
        customer: customer,
        transaction_type: "payment",
        status: "completed",
      ).sum(:amount)

      total_refunded = Transaction.where(
        store: store,
        customer: customer,
        transaction_type: "refund",
        status: "completed",
      ).where.not(id: id).sum(:amount)

      if (total_refunded + amount) > total_paid
        errors.add(:amount, "el reembolso no puede exceder el monto total pagado")
      end
    end
  end
end
