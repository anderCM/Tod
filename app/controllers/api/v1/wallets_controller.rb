# frozen_string_literal: true

module Api
  module V1
    class WalletsController < ApplicationController
      before_action :authenticate_store!

      def index
        wallets = current_store.wallets.active

        render json: wallets, each_serializer: WalletSerializer, status: :ok
      end
    end
  end
end
