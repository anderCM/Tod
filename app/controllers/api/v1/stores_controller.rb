# frozen_string_literal: true

module Api
  module V1
    class StoresController < ApplicationController
      before_action :authenticate_store!, except: [:create]

      def show
        render json: current_store, serializer: StoreSerializer, status: :ok
      end

      def update
        if current_store.update(update_params)
          render json: current_store, serializer: StoreSerializer, status: :ok
        else
          render json: { errors: current_store.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def create
        store = Store.new(store_params)

        if store.save
          token = generate_authentication_token
          store.update(authentication_token: token)
          render json: { 
            store: StoreSerializer.new(store),
            token: token 
          }, status: :created
        else
          render json: { errors: store.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def reconciliation_rules
        service = StoreReconciliationRules::GetRulesService.new(store: current_store)
        service.call

        if service.valid?
          render json: { rules: service.rules }, status: :ok
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      def update_reconciliation_rules
        service = StoreReconciliationRules::UpdateRulesService.new(
          store: current_store,
          rules_params: update_reconciliation_rules_params[:rules]
        )
        service.call

        if service.valid?
          render json: { rules: service.updated_rules }, status: :ok
        else
          render json: { errors: service.errors }, status: :unprocessable_entity
        end
      end

      private

      def store_params
        params.require(:store).permit(:email, :password, :name, :tax_id, :phone, :address, :description)
      end
      
      def update_params
        params.require(:store).permit(:name, :phone, :address, :description, :password)
      end

      def update_reconciliation_rules_params
        params.require(:store).permit(rules: [:rule_id, :tolerance_value, :active, :priority])
      end

      def generate_authentication_token
        SecureRandom.hex(32)
      end
    end
  end
end
