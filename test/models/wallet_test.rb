# frozen_string_literal: true

require "test_helper"

class WalletTest < ActiveSupport::TestCase
  def setup
    @owner = stores(:one)
    @wallet = Wallet.new(
      owner: @owner,
      wallet_type: "store",
      balance: 10000,
      status: "active",
    )
  end

  test "should be valid with valid attributes" do
    assert @wallet.valid?
  end

  test "should require owner" do
    @wallet.owner = nil
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:owner], "must exist"
  end

  test "should require balance" do
    @wallet.balance = nil
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:balance], "can't be blank"
  end

  test "should require non-negative balance" do
    @wallet.balance = -1
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:balance], "must be greater than or equal to 0"
  end

  test "should require wallet_type" do
    @wallet.wallet_type = nil
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:wallet_type], "can't be blank"
  end

  test "should require valid wallet_type" do
    @wallet.wallet_type = "otro"
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:wallet_type], "is not included in the list"
  end

  test "should require status" do
    @wallet.status = nil
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:status], "can't be blank"
  end

  test "should require valid status" do
    @wallet.status = "otro"
    assert_not @wallet.valid?
    assert_includes @wallet.errors[:status], "is not included in the list"
  end

  test "active scope should return only active wallets" do
    @wallet.save!
    inactive = @wallet.dup
    inactive.owner = stores(:two)
    inactive.status = "inactive"
    inactive.save!
    assert_includes Wallet.active, @wallet
    assert_not_includes Wallet.active, inactive
  end

  test "store_wallets scope should return only store wallets" do
    @wallet.save!
    customer_wallet = @wallet.dup
    customer_wallet.owner = customers(:one)
    customer_wallet.wallet_type = "customer"
    customer_wallet.save!
    assert_includes Wallet.store_wallets, @wallet
    assert_not_includes Wallet.store_wallets, customer_wallet
  end

  test "customer_wallets scope should return only customer wallets" do
    customer_wallet = @wallet.dup
    customer_wallet.owner = customers(:one)
    customer_wallet.wallet_type = "customer"
    customer_wallet.save!
    @wallet.save!
    assert_includes Wallet.customer_wallets, customer_wallet
    assert_not_includes Wallet.customer_wallets, @wallet
  end

  test "with_balance scope should return only wallets with positive balance" do
    @wallet.save!
    zero_wallet = @wallet.dup
    zero_wallet.owner = stores(:two)
    zero_wallet.balance = 0
    zero_wallet.save!
    assert_includes Wallet.with_balance, @wallet
    assert_not_includes Wallet.with_balance, zero_wallet
  end
end
