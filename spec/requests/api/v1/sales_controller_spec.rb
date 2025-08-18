require 'rails_helper'

RSpec.describe "Api::V1::Sales", type: :request do
  let(:store) { create(:store, authentication_token: 'valid_token_123') }
  let(:other_store) { create(:store, authentication_token: 'other_token_456') }
  let(:customer) { create(:customer) }
  
  describe 'GET /api/v1/sales' do
    context 'when authenticated' do
      let!(:store_sales) do
        create_list(:sale, 3, store: store, customer: customer)
      end

      let!(:other_store_sales) do
        create_list(:sale, 2, store: other_store, customer: customer)
      end

      before do
        get '/api/v1/sales', headers: auth_headers(store.authentication_token)
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns only the current store sales' do
        json_response = parsed_response

        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(3)

        returned_ids = json_response.map { |sale| sale['id'] }
        expected_ids = store_sales.map(&:id)

        expect(returned_ids).to match_array(expected_ids)
      end

      it 'does not return other store sales' do
        json_response = parsed_response

        other_store_ids = other_store_sales.map(&:id)
        returned_ids = json_response.map { |sale| sale['id'] }

        expect(returned_ids).not_to include(*other_store_ids)
      end

      it 'returns sales with correct attributes' do
        json_response = parsed_response
        first_sale = json_response.first

        expect(first_sale).to have_key('id')
        expect(first_sale).to have_key('sale_number')
        expect(first_sale).to have_key('total_amount')
        expect(first_sale).to have_key('sale_date')
        expect(first_sale).to have_key('status')
        expect(first_sale).to have_key('description')
        expect(first_sale).to have_key('metadata')
      end

      it 'returns sales with correct data' do
        json_response = parsed_response
        first_sale_json = json_response.first
        first_sale = store_sales.find { |s| s.id == first_sale_json['id'] }

        expect(first_sale_json['sale_number']).to eq(first_sale.sale_number)
        expect(first_sale_json['total_amount'].to_f).to eq(first_sale.total_amount.to_f)
        expect(first_sale_json['status']).to eq(first_sale.status)
        expect(first_sale_json['description']).to eq(first_sale.description)
      end
    end

    context 'when store has no sales' do
      before do
        get '/api/v1/sales', headers: auth_headers(store.authentication_token)
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns empty array' do
        json_response = parsed_response

        expect(json_response).to eq([])
      end
    end

    context 'when not authenticated' do
      before do
        get '/api/v1/sales', headers: json_headers
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        json_response = parsed_response

        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid authentication token' do
      before do
        get '/api/v1/sales', headers: auth_headers('invalid_token')
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with different sale statuses' do
      let!(:completed_sale) { create(:sale, store: store, customer: customer, status: 'completed') }
      let!(:pending_sale) { create(:sale, store: store, customer: customer, status: 'pending') }
      let!(:cancelled_sale) { create(:sale, store: store, customer: customer, status: 'cancelled') }
      let!(:refunded_sale) { create(:sale, store: store, customer: customer, status: 'refunded') }

      before do
        get '/api/v1/sales', headers: auth_headers(store.authentication_token)
      end

      it 'returns all sales regardless of status' do
        json_response = parsed_response

        expect(json_response.size).to eq(4)

        statuses = json_response.map { |sale| sale['status'] }
        expect(statuses).to include('completed', 'pending', 'cancelled', 'refunded')
      end
    end

    context 'with sales from different dates' do
      let!(:old_sale) { create(:sale, store: store, customer: customer, sale_date: 2.months.ago) }
      let!(:recent_sale) { create(:sale, store: store, customer: customer, sale_date: 1.day.ago) }
      let!(:today_sale) { create(:sale, store: store, customer: customer, sale_date: Time.current) }

      before do
        get '/api/v1/sales', headers: auth_headers(store.authentication_token)
      end

      it 'returns all sales regardless of date' do
        json_response = parsed_response

        expect(json_response.size).to eq(3)

        returned_ids = json_response.map { |sale| sale['id'] }
        expected_ids = [old_sale.id, recent_sale.id, today_sale.id]

        expect(returned_ids).to match_array(expected_ids)
      end
    end
  end
end
