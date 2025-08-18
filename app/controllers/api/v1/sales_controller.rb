# frozen_string_literal: true

module Api
  module V1
    class SalesController < ApplicationController
      before_action :authenticate_store!
      
      # Not necessary to paginate here as we do not have
      # a lot of transactions for every store
      def index
        transactions = current_store.sales

        render json: transactions, each_serializer: SaleSerializer, status: :ok
      end
    end
  end
end
