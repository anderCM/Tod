# frozen_string_literal: true

module Api
  module V1
    class TransactionsController < ApplicationController
      before_action :authenticate_store!
      
      # Not necessary to paginate here as we do not have
      # a lot of transactions for every store
      def index
        transactions = current_store.transactions

        render json: transactions, each_serializer: TransactionSerializer, status: :ok
      end
    end
  end
end
