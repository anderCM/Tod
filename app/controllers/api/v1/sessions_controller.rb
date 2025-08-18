# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ApplicationController
      before_action :authenticate_store!, only: [:destroy]

      def create
        store = Store.find_by(email: params[:email])

        if store && store.valid_password?(params[:password])
          token = generate_authentication_token
          store.update(authentication_token: token)
          render json: { 
            store: StoreSerializer.new(store),
            token: token 
          }, status: :ok
        else
          render json: { error: 'Correo o contraseña inválido' }, status: :unauthorized
        end
      end

      def destroy
        current_store.update(authentication_token: nil) if current_store
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      private

      def session_params
        params.permit(:email, :password)
      end

      def generate_authentication_token
        SecureRandom.hex(32)
      end
    end
  end
end
