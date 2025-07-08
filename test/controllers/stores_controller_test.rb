# frozen_string_literal: true

require "test_helper"

class StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @store = stores(:one)
  end

  test "should get index" do
    get stores_url
    assert_response :success
    assert_select "h1", /Tiendas|Stores/i
  end

  test "should create store" do
    assert_difference("Store.count") do
      post stores_url, params: {
        store: {
          name: "Nueva Tienda",
          description: "Una tienda de prueba",
          status: "active",
          tax_id: "99999999-9",
          address: "Calle Falsa 123",
          phone: "+56911112222",
          email: "nueva@tienda.com",
        },
      }
    end
    assert_redirected_to store_path(Store.last)
  end

  test "should update store" do
    patch store_url(@store), params: {
      store: {
        name: "Tienda Actualizada",
        tax_id: "77777777-7",
        email: "actualizada_unica@tienda.com",
        phone: "+56977778888",
        status: "active",
        address: "Nueva dirección 123",
        description: "Descripción actualizada",
      },
    }
    assert_redirected_to store_path(@store)
    @store.reload
    assert_equal "Tienda Actualizada", @store.name
  end

  test "should destroy store" do
    store = Store.create!(
      name: "Tienda Temporal",
      description: "Para test destroy",
      status: "active",
      tax_id: "55555555-5",
      address: "Calle Temporal 123",
      phone: "+56955555555",
      email: "temporal@tienda.com",
    )
    assert_difference("Store.count", -1) do
      delete store_url(store)
    end
    assert_redirected_to stores_url
  end

  test "should get transactions" do
    get transactions_store_url(@store)
    assert_response :success
    assert_select "h1", /Transacciones|Transactions/i
  end

  test "should get summary" do
    get summary_store_path(@store), as: :html
    assert_response :success
    assert_select "h1", /Resumen|Summary/i
  end
end
