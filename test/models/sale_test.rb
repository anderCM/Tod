# frozen_string_literal: true

require "test_helper"

class SaleTest < ActiveSupport::TestCase
  def setup
    @store = stores(:one)
    @customer = customers(:one)
    @sale = Sale.new(
      store: @store,
      customer: @customer,
      total_amount: 10000,
      status: "pending",
    )
  end

  test "should be valid with valid attributes" do
    assert @sale.valid?
  end

  test "should require store" do
    @sale.store = nil
    assert_not @sale.valid?
    assert_includes @sale.errors[:store], "must exist"
  end

  test "should require customer" do
    @sale.customer = nil
    assert_not @sale.valid?
    assert_includes @sale.errors[:customer], "must exist"
  end

  test "should require total_amount" do
    @sale.total_amount = nil
    assert_not @sale.valid?
    assert_includes @sale.errors[:total_amount], "can't be blank"
  end

  test "should require total_amount greater than 0" do
    @sale.total_amount = 0
    assert_not @sale.valid?
    assert_includes @sale.errors[:total_amount], "must be greater than 0"
  end

  test "should require status" do
    @sale.status = nil
    assert_not @sale.valid?
    assert_includes @sale.errors[:status], "can't be blank"
  end

  test "should require valid status" do
    @sale.status = "otro"
    assert_not @sale.valid?
    assert_includes @sale.errors[:status], "is not included in the list"
  end

  test "should generate sale_number on create" do
    @sale.save!
    assert @sale.sale_number.present?
  end

  test "should require unique sale_number" do
    @sale.save!
    duplicate = @sale.dup
    duplicate.sale_number = @sale.sale_number
    duplicate.total_amount = 20000
    duplicate.status = "completed"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sale_number], "has already been taken"
  end

  test "completed scope should return only completed sales" do
    @sale.status = "completed"
    @sale.save!
    pending = @sale.dup
    pending.sale_number = "SALE-99999999-9999"
    pending.status = "pending"
    pending.save!
    assert_includes Sale.completed, @sale
    assert_not_includes Sale.completed, pending
  end

  test "by_store scope should filter by store" do
    @sale.save!
    other_store = stores(:two)
    other_sale = @sale.dup
    other_sale.sale_number = "SALE-88888888-8888"
    other_sale.store = other_store
    other_sale.save!
    assert_includes Sale.by_store(@store), @sale
    assert_not_includes Sale.by_store(@store), other_sale
  end

  test "can_be_cancelled? should return true for pending and completed" do
    @sale.status = "pending"
    assert @sale.can_be_cancelled?
    @sale.status = "completed"
    assert @sale.can_be_cancelled?
  end

  test "can_be_cancelled? should return false for cancelled and refunded" do
    @sale.status = "cancelled"
    assert_not @sale.can_be_cancelled?
    @sale.status = "refunded"
    assert_not @sale.can_be_cancelled?
  end

  test "can_be_refunded? should return true only for completed" do
    @sale.status = "completed"
    assert @sale.can_be_refunded?
    @sale.status = "pending"
    assert_not @sale.can_be_refunded?
  end

  test "cancel! should update status to cancelled" do
    @sale.status = "pending"
    @sale.save!
    assert @sale.cancel!
    assert_equal "cancelled", @sale.status
  end

  test "refund! should update status to refunded" do
    @sale.status = "completed"
    @sale.save!
    assert @sale.refund!
    assert_equal "refunded", @sale.status
  end

  test "complete! should update status to completed" do
    @sale.status = "pending"
    @sale.save!
    @sale.complete!
    assert_equal "completed", @sale.status
  end
end
