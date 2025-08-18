require 'rails_helper'

RSpec.describe "Api::V1::Transactions", type: :request do
  let(:store) { create(:store, authentication_token: 'valid_token_123') }
  let(:other_store) { create(:store, authentication_token: 'other_token_456') }
  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:store_wallet) { create(:wallet, :store_wallet, owner: store) }
  let(:other_store_wallet) { create(:wallet, :store_wallet, owner: other_store) }

  describe 'GET /api/v1/transactions' do
    context 'when authenticated' do
      let!(:store_transactions) do
        create_list(:transaction, 3, 
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      let!(:other_store_transactions) do
        create_list(:transaction, 2, 
          store: other_store, 
          customer: other_customer,
          wallet: other_store_wallet
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns only the current store transactions' do
        json_response = parsed_response

        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(3)

        returned_ids = json_response.map { |transaction| transaction['id'] }
        expected_ids = store_transactions.map(&:id)

        expect(returned_ids).to match_array(expected_ids)
      end

      it 'does not return other store transactions' do
        json_response = parsed_response

        other_store_ids = other_store_transactions.map(&:id)
        returned_ids = json_response.map { |transaction| transaction['id'] }

        expect(returned_ids).not_to include(*other_store_ids)
      end

      it 'returns transactions with correct attributes' do
        json_response = parsed_response
        first_transaction = json_response.first

        expect(first_transaction).to have_key('id')
        expect(first_transaction).to have_key('amount')
        expect(first_transaction).to have_key('transaction_type')
        expect(first_transaction).to have_key('description')
        expect(first_transaction).to have_key('reference')
        expect(first_transaction).to have_key('status')
        expect(first_transaction).to have_key('transaction_date')
      end

      it 'returns transactions with correct data' do
        json_response = parsed_response
        first_transaction_json = json_response.first
        first_transaction = store_transactions.find { |t| t.id == first_transaction_json['id'] }

        expect(first_transaction_json['amount'].to_f).to eq(first_transaction.amount.to_f)
        expect(first_transaction_json['transaction_type']).to eq(first_transaction.transaction_type)
        expect(first_transaction_json['description']).to eq(first_transaction.description)
        expect(first_transaction_json['reference']).to eq(first_transaction.reference)
        expect(first_transaction_json['status']).to eq(first_transaction.status)
      end

      it 'does not include sensitive wallet information' do
        json_response = parsed_response
        first_transaction = json_response.first

        expect(first_transaction).not_to have_key('wallet')
        expect(first_transaction).not_to have_key('wallet_id')
        expect(first_transaction).not_to have_key('store')
        expect(first_transaction).not_to have_key('store_id')
        expect(first_transaction).not_to have_key('customer')
        expect(first_transaction).not_to have_key('customer_id')
      end
    end

    context 'when store has no transactions' do
      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
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
        get '/api/v1/transactions', headers: json_headers
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
        get '/api/v1/transactions', headers: auth_headers('invalid_token')
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with different transaction types' do
      let!(:payment_transaction) do
        create(:transaction, 
          store: store, 
          customer: customer,
          wallet: store_wallet,
          transaction_type: 'payment'
        )
      end
      
      let!(:refund_transaction) do
        create(:transaction, :refund,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end
      
      let!(:fee_transaction) do
        create(:transaction, :fee,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end
      
      let!(:deposit_transaction) do
        create(:transaction, :deposit,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns all transaction types' do
        json_response = parsed_response

        expect(json_response.size).to eq(4)

        types = json_response.map { |transaction| transaction['transaction_type'] }
        expect(types).to include('payment', 'refund', 'fee', 'deposit')
      end
    end

    context 'with different transaction statuses' do
      let!(:completed_transaction) do
        create(:transaction, 
          store: store, 
          customer: customer,
          wallet: store_wallet,
          status: 'completed'
        )
      end

      let!(:pending_transaction) do
        create(:transaction, :pending,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      let!(:failed_transaction) do
        create(:transaction, :failed,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns all transactions regardless of status' do
        json_response = parsed_response

        expect(json_response.size).to eq(3)

        statuses = json_response.map { |transaction| transaction['status'] }
        expect(statuses).to include('completed', 'pending', 'failed')
      end
    end

    context 'with transactions from different dates' do
      let!(:old_transaction) do
        create(:transaction, :old,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      let!(:recent_transaction) do
        create(:transaction, :recent,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      let!(:today_transaction) do
        create(:transaction,
          store: store, 
          customer: customer,
          wallet: store_wallet,
          transaction_date: Time.current
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns all transactions regardless of date' do
        json_response = parsed_response

        expect(json_response.size).to eq(3)

        returned_ids = json_response.map { |transaction| transaction['id'] }
        expected_ids = [old_transaction.id, recent_transaction.id, today_transaction.id]

        expect(returned_ids).to match_array(expected_ids)
      end
    end

    context 'with different customers' do
      let(:customer1) { create(:customer) }
      let(:customer2) { create(:customer) }
      let(:customer3) { create(:customer) }

      let!(:customer1_transactions) do
        create_list(:transaction, 2,
          store: store, 
          customer: customer1,
          wallet: store_wallet
        )
      end

      let!(:customer2_transactions) do
        create_list(:transaction, 3,
          store: store, 
          customer: customer2,
          wallet: store_wallet
        )
      end

      let!(:customer3_transactions) do
        create(:transaction,
          store: store, 
          customer: customer3,
          wallet: store_wallet
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns transactions from all customers' do
        json_response = parsed_response

        expect(json_response.size).to eq(6)

        all_expected_ids = (customer1_transactions + customer2_transactions + [customer3_transactions]).map(&:id)
        returned_ids = json_response.map { |transaction| transaction['id'] }

        expect(returned_ids).to match_array(all_expected_ids)
      end
    end

    context 'with large amounts' do
      let!(:small_transaction) do
        create(:transaction,
          store: store, 
          customer: customer,
          wallet: store_wallet,
          amount: 100
        )
      end

      let!(:medium_transaction) do
        create(:transaction,
          store: store, 
          customer: customer,
          wallet: store_wallet,
          amount: 50000
        )
      end

      let!(:large_transaction) do
        create(:transaction, :large_amount,
          store: store, 
          customer: customer,
          wallet: store_wallet
        )
      end

      before do
        get '/api/v1/transactions', headers: auth_headers(store.authentication_token)
      end

      it 'returns transactions with correct amounts' do
        json_response = parsed_response

        amounts = json_response.map { |t| t['amount'].to_f }
        expected_amounts = [100.0, 50000.0, 1000000.0]

        expect(amounts).to match_array(expected_amounts)
      end
    end
  end
end
