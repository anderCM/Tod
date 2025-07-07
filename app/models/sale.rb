# frozen_string_literal: true

class Sale < ApplicationRecord
  belongs_to :store
  belongs_to :customer
  has_one :payment_transaction, class_name: "Transaction", dependent: :destroy

  validates :sale_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :sale_date, presence: true
  validates :status, presence: true, inclusion: { in: ["pending", "completed", "cancelled", "refunded"] }

  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :refunded, -> { where(status: "refunded") }
  scope :by_store, ->(store) { where(store: store) }
  scope :by_customer, ->(customer) { where(customer: customer) }
  scope :in_period, ->(start_date, end_date) { where(sale_date: start_date..end_date) }
  scope :recent, -> { where("sale_date >= ?", 30.days.ago) }

  before_validation :generate_sale_number, on: :create
  before_validation :set_sale_date, on: :create

  def can_be_cancelled?
    status == "pending" || status == "completed"
  end

  def can_be_refunded?
    status == "completed"
  end

  def cancel!
    return false unless can_be_cancelled?

    update!(status: "cancelled")
  end

  def refund!
    return false unless can_be_refunded?

    update!(status: "refunded")
  end

  def complete!
    update!(status: "completed")
  end

  def summary
    {
      id: id,
      sale_number: sale_number,
      store_name: store.name,
      customer_name: customer.name,
      total_amount: total_amount,
      status: status,
      sale_date: sale_date,
      description: description,
    }
  end

  class << self
    def total_sales_by_period(start_date, end_date, status = "completed")
      where(status: status, sale_date: start_date..end_date).sum(:total_amount)
    end

    def count_by_period(start_date, end_date, status = "completed")
      where(status: status, sale_date: start_date..end_date).count
    end

    def summary_by_period(start_date, end_date)
      sales = where(sale_date: start_date..end_date)

      {
        total_count: sales.count,
        completed_count: sales.where(status: "completed").count,
        pending_count: sales.where(status: "pending").count,
        cancelled_count: sales.where(status: "cancelled").count,
        refunded_count: sales.where(status: "refunded").count,
        total_amount: sales.where(status: "completed").sum(:total_amount),
        pending_amount: sales.where(status: "pending").sum(:total_amount),
        by_status: sales.group(:status).count,
      }
    end
  end

  private

  def generate_sale_number
    return if sale_number.present?

    prefix = "SALE"
    date_part = Date.current.strftime("%Y%m%d")
    sequence = Sale.where("sale_number LIKE ?", "#{prefix}-#{date_part}-%").count + 1

    self.sale_number = "#{prefix}-#{date_part}-#{sequence.to_s.rjust(4, "0")}"
  end

  def set_sale_date
    self.sale_date ||= Time.current
  end
end
