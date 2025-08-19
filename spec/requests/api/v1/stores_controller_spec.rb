require 'rails_helper'

RSpec.describe "Api::V1::Stores", type: :request do
  let(:store) { create(:store, authentication_token: 'valid_token_123') }
  let(:other_store) { create(:store, authentication_token: 'other_token_456') }

  describe 'GET /api/v1/profile' do
    context 'when authenticated' do
      before do
        get '/api/v1/profile', headers: auth_headers(store.authentication_token)
      end

      it 'returns success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns current store information' do
        json_response = parsed_response

        expect(json_response['id']).to eq(store.id)
        expect(json_response['email']).to eq(store.email)
        expect(json_response['name']).to eq(store.name)
        expect(json_response['status']).to eq(store.status)
        expect(json_response['tax_id']).to eq(store.tax_id)
        expect(json_response['phone']).to eq(store.phone)
      end

      it 'returns store with correct attributes' do
        json_response = parsed_response

        expect(json_response).to have_key('id')
        expect(json_response).to have_key('email')
        expect(json_response).to have_key('name')
        expect(json_response).to have_key('status')
        expect(json_response).to have_key('tax_id')
        expect(json_response).to have_key('phone')
        expect(json_response).to have_key('address')
        expect(json_response).to have_key('description')
      end

      it 'does not return sensitive information' do
        json_response = parsed_response

        expect(json_response).not_to have_key('password')
        expect(json_response).not_to have_key('password_digest')
        expect(json_response).not_to have_key('authentication_token')
      end
    end

    context 'when not authenticated' do
      before do
        get '/api/v1/profile', headers: json_headers
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        json_response = parsed_response
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'PUT /api/v1/profile' do
    context 'when authenticated' do
      context 'with valid parameters' do
        let(:update_params) do
          {
            store: {
              name: 'Updated Store Name',
              phone: '+56 9 8765 4321',
              address: '123 New Street',
              description: 'Updated description'
            }
          }.to_json
        end

        before do
          put '/api/v1/profile', params: update_params, headers: auth_headers(store.authentication_token)
        end

        it 'returns success status' do
          expect(response).to have_http_status(:ok)
        end

        it 'updates the store' do
          store.reload
          expect(store.name).to eq('Updated Store Name')
          expect(store.phone).to eq('+56 9 8765 4321')
          expect(store.address).to eq('123 New Street')
          expect(store.description).to eq('Updated description')
        end

        it 'returns updated store information' do
          json_response = parsed_response

          expect(json_response['name']).to eq('Updated Store Name')
          expect(json_response['phone']).to eq('+56 9 8765 4321')
          expect(json_response['address']).to eq('123 New Street')
          expect(json_response['description']).to eq('Updated description')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            store: {
              name: '',
              phone: 'invalid_phone'
            }
          }.to_json
        end

        before do
          put '/api/v1/profile', params: invalid_params, headers: auth_headers(store.authentication_token)
        end

        it 'returns unprocessable entity status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          json_response = parsed_response

          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
        end

        it 'does not update the store' do
          original_name = store.name
          store.reload
          expect(store.name).to eq(original_name)
        end
      end

      context 'updating password' do
        let(:password_params) do
          {
            store: {
              password: 'newpassword123'
            }
          }.to_json
        end

        before do
          put '/api/v1/profile', params: password_params, headers: auth_headers(store.authentication_token)
        end

        it 'updates the password' do
          store.reload
          expect(store.valid_password?('newpassword123')).to be true
        end
      end

      context 'trying to update protected fields' do
        let(:protected_params) do
          {
            store: {
              email: 'newemail@example.com',
              tax_id: '87654321-0',
              status: 'suspended'
            }
          }.to_json
        end

        before do
          put '/api/v1/profile', params: protected_params, headers: auth_headers(store.authentication_token)
        end

        it 'does not update protected fields' do
          original_email = store.email
          original_tax_id = store.tax_id
          original_status = store.status

          store.reload

          expect(store.email).to eq(original_email)
          expect(store.tax_id).to eq(original_tax_id)
          expect(store.status).to eq(original_status)
        end
      end
    end

    context 'when not authenticated' do
      let(:update_params) do
        {
          store: {
            name: 'Updated Store Name'
          }
        }.to_json
      end

      before do
        put '/api/v1/profile', params: update_params, headers: json_headers
      end

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/register' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          store: {
            email: 'newstore@example.com',
            password: 'password123',
            name: 'New Store',
            tax_id: '98765432-1',
            phone: '+56 9 1111 2222',
            address: '456 Store Street',
            description: 'A new store'
          }
        }.to_json
      end

      it 'creates a new store' do
        expect {
          post '/api/v1/register', params: valid_params, headers: json_headers
        }.to change(Store, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/register', params: valid_params, headers: json_headers
        expect(response).to have_http_status(:created)
      end

      it 'returns store information with token' do
        post '/api/v1/register', params: valid_params, headers: json_headers
        json_response = parsed_response

        expect(json_response).to have_key('store')
        expect(json_response).to have_key('token')

        expect(json_response['store']['email']).to eq('newstore@example.com')
        expect(json_response['store']['name']).to eq('New Store')
        expect(json_response['token']).to be_present
      end

      it 'generates authentication token' do
        post '/api/v1/register', params: valid_params, headers: json_headers
        json_response = parsed_response

        new_store = Store.find_by(email: 'newstore@example.com')
        expect(new_store.authentication_token).to be_present
        expect(new_store.authentication_token).to eq(json_response['token'])
      end
    end

    context 'with invalid parameters' do
      context 'missing required fields' do
        let(:invalid_params) do
          {
            store: {
              email: 'newstore@example.com'
            }
          }.to_json
        end

        it 'does not create a store' do
          expect {
            post '/api/v1/register', params: invalid_params, headers: json_headers
          }.not_to change(Store, :count)
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/register', params: invalid_params, headers: json_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post '/api/v1/register', params: invalid_params, headers: json_headers
          json_response = parsed_response

          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
        end
      end

      context 'invalid email format' do
        let(:invalid_params) do
          {
            store: {
              email: 'invalid_email',
              password: 'password123',
              name: 'New Store',
              tax_id: '98765432-1',
              phone: '+56 9 1111 2222'
            }
          }.to_json
        end

        it 'returns error for invalid email' do
          post '/api/v1/register', params: invalid_params, headers: json_headers
          json_response = parsed_response

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].join(' ')).to include('Email')
        end
      end

      context 'duplicate email' do
        let(:duplicate_params) do
          {
            store: {
              email: store.email,
              password: 'password123',
              name: 'Another Store',
              tax_id: '11111111-1',
              phone: '+56 9 2222 3333'
            }
          }.to_json
        end

        it 'returns error for duplicate email' do
          post '/api/v1/register', params: duplicate_params, headers: json_headers
          json_response = parsed_response

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].join(' ')).to include('Email')
        end
      end

      context 'duplicate tax_id' do
        let(:duplicate_params) do
          {
            store: {
              email: 'unique@example.com',
              password: 'password123',
              name: 'Another Store',
              tax_id: store.tax_id,
              phone: '+56 9 3333 4444'
            }
          }.to_json
        end

        it 'returns error for duplicate tax_id' do
          post '/api/v1/register', params: duplicate_params, headers: json_headers
          json_response = parsed_response

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].join(' ')).to include('Tax')
        end
      end

      context 'invalid phone format' do
        let(:invalid_params) do
          {
            store: {
              email: 'valid@example.com',
              password: 'password123',
              name: 'New Store',
              tax_id: '22222222-2',
              phone: '123456789'
            }
          }.to_json
        end

        it 'returns error for invalid phone' do
          post '/api/v1/register', params: invalid_params, headers: json_headers
          json_response = parsed_response

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].join(' ')).to include('Phone')
        end
      end
    end
  end

  describe 'GET /api/v1/reconciliation_rules' do
    context 'when authenticated' do
      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:call)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:valid?).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:rules).and_return([
          { rule_id: 1, tolerance_value: 100, active: true, priority: 1 }
        ])
      end

      it 'returns success status' do
        get '/api/v1/reconciliation_rules', headers: auth_headers(store.authentication_token)
        expect(response).to have_http_status(:ok)
      end

      it 'returns reconciliation rules' do
        get '/api/v1/reconciliation_rules', headers: auth_headers(store.authentication_token)
        json_response = parsed_response

        expect(json_response).to have_key('rules')
        expect(json_response['rules']).to be_an(Array)
      end
    end

    context 'when service fails' do
      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:call)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:valid?).and_return(false)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService).to receive(:errors).and_return(['Error message'])
      end

      it 'returns unprocessable entity status' do
        get '/api/v1/reconciliation_rules', headers: auth_headers(store.authentication_token)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        get '/api/v1/reconciliation_rules', headers: auth_headers(store.authentication_token)
        json_response = parsed_response

        expect(json_response).to have_key('errors')
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized status' do
        get '/api/v1/reconciliation_rules', headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/reconciliation_rules' do
    context 'when authenticated' do
      let(:rules_params) do
        {
          store: {
            rules: [
              { rule_id: 1, tolerance_value: 200, active: false, priority: 2 }
            ]
          }
        }.to_json
      end

      context 'when service succeeds' do
        before do
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:call)
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:valid?).and_return(true)
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:updated_rules).and_return([
            { rule_id: 1, tolerance_value: 200, active: false, priority: 2 }
          ])
        end

        it 'returns success status' do
          post '/api/v1/reconciliation_rules', params: rules_params, headers: auth_headers(store.authentication_token)
          expect(response).to have_http_status(:ok)
        end

        it 'returns updated rules' do
          post '/api/v1/reconciliation_rules', params: rules_params, headers: auth_headers(store.authentication_token)
          json_response = parsed_response

          expect(json_response).to have_key('rules')
          expect(json_response['rules']).to be_an(Array)
        end
      end

      context 'when service fails' do
        before do
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:call)
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:valid?).and_return(false)
          allow_any_instance_of(StoreReconciliationRules::UpdateRulesService).to receive(:errors).and_return(['Update failed'])
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/reconciliation_rules', params: rules_params, headers: auth_headers(store.authentication_token)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post '/api/v1/reconciliation_rules', params: rules_params, headers: auth_headers(store.authentication_token)
          json_response = parsed_response

          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to include('Update failed')
        end
      end
    end

    context 'when not authenticated' do
      let(:rules_params) do
        {
          store: {
            rules: []
          }
        }.to_json
      end

      it 'returns unauthorized status' do
        post '/api/v1/reconciliation_rules', params: rules_params, headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
