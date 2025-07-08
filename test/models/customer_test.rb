# frozen_string_literal: true

require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  def setup
    @customer = Customer.new(
      name: "Juan Pérez",
      email: "juan.perez@email.com",
      phone: "+56912345678",
      document_number: "99999999-9",
      status: "active",
    )
  end

  test "should be valid with valid attributes" do
    assert @customer.valid?
  end

  test "should require name" do
    @customer.name = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:name], "can't be blank"
  end

  test "should require name with minimum length" do
    @customer.name = "a"
    assert_not @customer.valid?
    assert_includes @customer.errors[:name], "is too short (minimum is 2 characters)"
  end

  test "should require email" do
    @customer.email = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    @customer.save!
    duplicate = @customer.dup
    duplicate.document_number = "87654321-0"
    duplicate.phone = "+56987654321"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "should require valid email format" do
    @customer.email = "noesemail"
    assert_not @customer.valid?
    assert_includes @customer.errors[:email], "is invalid"
  end

  test "should require phone" do
    @customer.phone = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:phone], "can't be blank"
  end

  test "should require valid phone format" do
    @customer.phone = "123"
    assert_not @customer.valid?
    assert_includes @customer.errors[:phone], "debe tener formato +56 X XXXX XXXX"
  end

  test "should require document_number" do
    @customer.document_number = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:document_number], "can't be blank"
  end

  test "should require unique document_number" do
    @customer.save!
    duplicate = @customer.dup
    duplicate.email = "otro@email.com"
    duplicate.phone = "+56987654321"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_number], "has already been taken"
  end

  test "should require valid document_number format" do
    @customer.document_number = "12345678"
    assert_not @customer.valid?
    assert_includes @customer.errors[:document_number], "debe tener formato de RUT chileno sin puntos (12345678-9)"
  end

  test "should require status" do
    @customer.status = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:status], "can't be blank"
  end

  test "should require valid status" do
    @customer.status = "otro"
    assert_not @customer.valid?
    assert_includes @customer.errors[:status], "is not included in the list"
  end

  test "active scope should return only active customers" do
    @customer.save!
    inactive = @customer.dup
    inactive.email = "inactivo@email.com"
    inactive.document_number = "22222222-2"
    inactive.phone = "+56987654321"
    inactive.status = "inactive"
    inactive.save!
    assert_includes Customer.active, @customer
    assert_not_includes Customer.active, inactive
  end

  test "by_name scope should filter by name" do
    @customer.save!
    other = @customer.dup
    other.email = "otro@email.com"
    other.document_number = "33333333-3"
    other.phone = "+56987654321"
    other.name = "Otro Cliente"
    other.save!
    assert_includes Customer.by_name("Juan"), @customer
    assert_not_includes Customer.by_name("Juan"), other
  end
end
