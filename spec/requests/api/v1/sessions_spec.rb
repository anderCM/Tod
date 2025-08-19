require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:store) { create(:store, email: 'test@store.com', password: 'password123', authentication_token: nil) }
  
  describe 'POST /api/v1/sessions' do
    context 'with valid credentials' do
      let(:valid_params) do
        {
          email: store.email,
          password: 'password123'
        }.to_json
      end

      it 'returns success status' do
        post '/api/v1/login', params: valid_params, headers: json_headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns authentication token' do
        post '/api/v1/login', params: valid_params, headers: json_headers
        json_response = parsed_response

        expect(json_response).to have_key('token')
        expect(json_response['token']).not_to be_nil
        expect(json_response['token']).to be_a(String)
      end

      it 'returns store information' do
        post '/api/v1/login', params: valid_params, headers: json_headers
        json_response = parsed_response

        expect(json_response).to have_key('store')
        expect(json_response['store']['email']).to eq(store.email)
        expect(json_response['store']['name']).to eq(store.name)
      end

      it 'updates store authentication token' do
        expect {
          post '/api/v1/login', params: valid_params, headers: json_headers
        }.to change { store.reload.authentication_token }

        expect(store.reload.authentication_token).not_to be_nil
      end
    end

    context 'with invalid email' do
      let(:invalid_params) do
        {
          email: 'wrong@email.com',
          password: 'password123'
        }.to_json
      end

      it 'returns unauthorized status' do
        post '/api/v1/login', params: invalid_params, headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post '/api/v1/login', params: invalid_params, headers: json_headers
        json_response = parsed_response

        expect(json_response['error']).to eq('Correo o contraseña inválido')
      end
    end

    context 'with invalid password' do
      let(:invalid_params) do
        {
          email: store.email,
          password: 'wrongpassword'
        }.to_json
      end

      it 'returns unauthorized status' do
        post '/api/v1/login', params: invalid_params, headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post '/api/v1/login', params: invalid_params, headers: json_headers
        json_response = parsed_response

        expect(json_response['error']).to eq('Correo o contraseña inválido')
      end
    end

    context 'with missing parameters' do
      let(:empty_params) { {}.to_json }

      it 'returns unauthorized status' do
        post '/api/v1/login', params: empty_params, headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/sessions' do
    context 'when authenticated' do
      let(:authenticated_store) { create(:store, authentication_token: 'valid_token_123') }

      it 'returns success status' do
        delete '/api/v1/logout', headers: auth_headers(authenticated_store.authentication_token)
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        delete '/api/v1/logout', headers: auth_headers(authenticated_store.authentication_token)
        json_response = parsed_response

        expect(json_response['message']).to eq('Logged out successfully')
      end

      it 'clears authentication token' do
        delete '/api/v1/logout', headers: auth_headers(authenticated_store.authentication_token)
        expect(authenticated_store.reload.authentication_token).to be_nil
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized status' do
        delete '/api/v1/logout', headers: json_headers
        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not affect any store tokens' do
        store_with_token = create(:store, authentication_token: 'some_token')

        delete '/api/v1/logout', headers: json_headers

        expect(store_with_token.reload.authentication_token).to eq('some_token')
      end
    end

    context 'with invalid token' do
      let(:invalid_headers) do
        {
          'Authorization' => 'Bearer invalid_token',
          'Accept' => 'application/json'
        }
      end

      it 'returns unauthorized status' do
        delete '/api/v1/logout', headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end