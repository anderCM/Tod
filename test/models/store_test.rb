# frozen_string_literal: true

require "test_helper"

class StoreTest < ActiveSupport::TestCase
  def setup
    @store = Store.new(
      name: "Tienda de Prueba",
      tax_id: "11223344-5",
      address: "Calle Principal 123",
      phone: "+56912345678",
      email: "tienda@test.com",
      status: "active",
    )
  end

  test "should be valid with valid attributes" do
    assert @store.valid?
  end

  test "should require name" do
    @store.name = nil
    assert_not @store.valid?
    assert_includes @store.errors[:name], "can't be blank"
  end

  test "should require name with minimum length" do
    @store.name = "a"
    assert_not @store.valid?
    assert_includes @store.errors[:name], "is too short (minimum is 2 characters)"
  end

  test "should require tax_id" do
    @store.tax_id = nil
    assert_not @store.valid?
    assert_includes @store.errors[:tax_id], "can't be blank"
  end

  test "should require unique tax_id" do
    @store.save!
    duplicate = @store.dup
    duplicate.email = "otra@tienda.com"
    duplicate.phone = "+56987654321"
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tax_id], "has already been taken"
  end

  test "should require valid tax_id format" do
    @store.tax_id = "12345678"
    assert_not @store.valid?
    assert_includes @store.errors[:tax_id], "debe tener formato de RUT chileno sin puntos (12345678-9)"
  end

  test "should require email" do
    @store.email = nil
    assert_not @store.valid?
    assert_includes @store.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @store.email = "noesemail"
    assert_not @store.valid?
    assert_includes @store.errors[:email], "is invalid"
  end

  test "should require phone" do
    @store.phone = nil
    assert_not @store.valid?
    assert_includes @store.errors[:phone], "can't be blank"
  end

  test "should require valid phone format" do
    @store.phone = "123"
    assert_not @store.valid?
    assert_includes @store.errors[:phone], "debe tener formato +56 X XXXX XXXX"
  end

  test "should require status" do
    @store.status = nil
    assert_not @store.valid?
    assert_includes @store.errors[:status], "can't be blank"
  end

  test "should require valid status" do
    @store.status = "otro"
    assert_not @store.valid?
    assert_includes @store.errors[:status], "is not included in the list"
  end

  test "active scope should return only active stores" do
    @store.save!
    inactive = @store.dup
    inactive.tax_id = "12345678-5"
    inactive.email = "inactiva@tienda.com"
    inactive.phone = "+56987654321"
    inactive.status = "inactive"
    inactive.save!
    assert_includes Store.active, @store
    assert_not_includes Store.active, inactive
  end

  test "by_name scope should filter by name" do
    @store.save!
    other = @store.dup
    other.tax_id = "11111111-1"
    other.email = "otra@tienda.com"
    other.phone = "+56987654321"
    other.name = "Otra Tienda"
    other.save!
    assert_includes Store.by_name("Prueba"), @store
    assert_not_includes Store.by_name("Prueba"), other
  end
end
