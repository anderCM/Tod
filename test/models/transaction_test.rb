# frozen_string_literal: true

require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @wallet = wallets(:one)
    @store = stores(:one)
    @customer = customers(:one)
    @transaction = Transaction.new(
      wallet: @wallet,
      store: @store,
      customer: @customer,
      amount: 10000,
      transaction_type: "payment",
      description: "Pago de compra",
      status: "completed",
    )
  end

  test "should be valid with valid attributes" do
    assert @transaction.valid?
  end

  test "should require wallet" do
    @transaction.wallet = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:wallet], "must exist"
  end

  test "should require store" do
    @transaction.store = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:store], "must exist"
  end

  test "should require customer" do
    @transaction.customer = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:customer], "must exist"
  end

  test "should require amount" do
    @transaction.amount = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:amount], "can't be blank"
  end

  test "should require amount greater than 0" do
    @transaction.amount = 0
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:amount], "must be greater than 0"
  end

  test "should require transaction_type" do
    @transaction.transaction_type = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:transaction_type], "can't be blank"
  end

  test "should require valid transaction_type" do
    @transaction.transaction_type = "otro"
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:transaction_type], "is not included in the list"
  end

  test "should require description" do
    @transaction.description = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:description], "can't be blank"
  end

  test "should require description with minimum length" do
    @transaction.description = "abc"
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:description], "is too short (minimum is 5 characters)"
  end

  test "should require status" do
    @transaction.status = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:status], "can't be blank"
  end

  test "should require valid status" do
    @transaction.status = "otro"
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:status], "is not included in the list"
  end

  test "should generate reference on create" do
    @transaction.save!
    assert @transaction.reference.present?
  end

  test "should require unique reference" do
    @transaction.save!
    duplicate = @transaction.dup
    duplicate.reference = @transaction.reference
    duplicate.amount = 20000
    duplicate.description = "Otro pago"
    duplicate.status = "completed"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference], "has already been taken"
  end

  test "completed scope should return only completed transactions" do
    @transaction.status = "completed"
    @transaction.save!
    pending = @transaction.dup
    pending.reference = "PAY-999999999999"
    pending.status = "pending"
    pending.save!
    assert_includes Transaction.completed, @transaction
    assert_not_includes Transaction.completed, pending
  end

  test "by_type scope should filter by transaction type" do
    @transaction.save!
    refund = @transaction.dup
    refund.reference = "REF-888888888888"
    refund.transaction_type = "refund"
    refund.save!
    assert_includes Transaction.by_type("payment"), @transaction
    assert_not_includes Transaction.by_type("payment"), refund
  end
end
