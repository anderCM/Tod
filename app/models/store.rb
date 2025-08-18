# frozen_string_literal: true

class Store < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :wallets, as: :owner, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :sales, dependent: :destroy

  enum :status, {
    active: 'active',
    inactive: 'inactive',
    suspended: 'suspended'
  }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :tax_id, presence: true, uniqueness: true, format: { with: /\A\d{7,8}-[0-9kK]\z/, message: "debe tener formato de RUT chileno sin puntos (12345678-9)" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A\+56\s?\d{1,2}\s?\d{4}\s?\d{4}\z/, message: "debe tener formato +56 X XXXX XXXX" }

  scope :with_transactions, -> { joins(:transactions).distinct }
  scope :by_name, ->(name) { where("LOWER(name) LIKE ?", "%#{name.downcase}%") }

  def total_transactions_amount(start_date = nil, end_date = nil)
    query = transactions.completed
    query = query.where(transaction_date: start_date..end_date) if start_date && end_date
    query.sum(:amount)
  end

  def pending_transactions_count
    transactions.pending.count
  end

  def failed_transactions_count
    transactions.failed.count
  end

  def wallet_balance
    wallets.first&.balance || 0
  end

  def transactions_in_period(start_date, end_date)
    transactions.where(transaction_date: start_date..end_date)
  end

  def transaction_summary(start_date = nil, end_date = nil)
    query = transactions
    query = query.where(transaction_date: start_date..end_date) if start_date && end_date

    {
      total_count: query.count,
      completed_count: query.completed.count,
      pending_count: query.pending.count,
      failed_count: query.failed.count,
      total_amount: query.completed.sum(:amount),
      pending_amount: query.pending.sum(:amount),
    }
  end
end
