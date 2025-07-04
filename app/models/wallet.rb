# frozen_string_literal: true

class Wallet < ApplicationRecord
  # Relaciones
  belongs_to :owner, polymorphic: true
  has_many :transactions, dependent: :destroy

  # Validaciones
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :wallet_type, presence: true, inclusion: { in: ["store", "customer"] }
  validates :status, presence: true, inclusion: { in: ["active", "inactive", "suspended"] }
  validates :owner, presence: true

  # Scopes útiles para conciliación
  scope :active, -> { where(status: "active") }
  scope :store_wallets, -> { where(wallet_type: "store") }
  scope :customer_wallets, -> { where(wallet_type: "customer") }
  scope :with_balance, -> { where("balance > 0") }

  # Métodos para conciliación
  def total_incoming_amount(start_date = nil, end_date = nil)
    query = transactions.where(transaction_type: ["payment", "transfer"])
    query = query.where(transaction_date: start_date..end_date) if start_date && end_date
    query.where(status: "completed").sum(:amount)
  end

  def total_outgoing_amount(start_date = nil, end_date = nil)
    # Para billeteras de clientes, los pagos son salidas
    # Para billeteras de tiendas, los reembolsos son salidas
    query = if wallet_type == "customer"
      transactions.where(transaction_type: ["payment", "transfer"])
    else
      transactions.where(transaction_type: ["refund"])
    end

    query = query.where(transaction_date: start_date..end_date) if start_date && end_date
    query.where(status: "completed").sum(:amount)
  end

  def pending_transactions_amount
    transactions.where(status: "pending").sum(:amount)
  end

  def failed_transactions_amount
    transactions.where(status: "failed").sum(:amount)
  end

  def transactions_count(start_date = nil, end_date = nil)
    query = transactions
    query = query.where(transaction_date: start_date..end_date) if start_date && end_date
    query.count
  end

  # Método para obtener transacciones por período (útil para conciliación)
  def transactions_in_period(start_date, end_date)
    transactions.where(transaction_date: start_date..end_date)
  end

  # Método para obtener resumen de transacciones (útil para conciliación)
  def transaction_summary(start_date = nil, end_date = nil)
    query = transactions
    query = query.where(transaction_date: start_date..end_date) if start_date && end_date

    {
      total_count: query.count,
      completed_count: query.where(status: "completed").count,
      pending_count: query.where(status: "pending").count,
      failed_count: query.where(status: "failed").count,
      total_amount: query.where(status: "completed").sum(:amount),
      pending_amount: query.where(status: "pending").sum(:amount),
      incoming_amount: total_incoming_amount(start_date, end_date),
      outgoing_amount: total_outgoing_amount(start_date, end_date),
    }
  end

  # Método para verificar si el balance es consistente (útil para conciliación)
  def balance_consistency_check
    expected_balance = calculate_expected_balance
    {
      current_balance: balance,
      expected_balance: expected_balance,
      difference: balance - expected_balance,
      is_consistent: (balance - expected_balance).abs < 0.01,
    }
  end

  private

  def calculate_expected_balance
    # Este método calcula el balance esperado basado en las transacciones
    # Es útil para detectar inconsistencias en la conciliación
    incoming = total_incoming_amount
    outgoing = total_outgoing_amount

    # El cálculo es el mismo para ambos tipos de billetera
    incoming - outgoing
  end
end
