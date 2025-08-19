# frozen_string_literal: true

module Api
  module V1
    class ReconciliationsController < ApplicationController
      before_action :authenticate_store!

      # Not necessary to paginate here as we do not have
      # a lot of reconciliations for every store
      def index
        reconciliations = current_store.reconciliations
                                       .includes(reconciliation_items: [:source, :target])
                                       .order(created_at: :desc)

        render json: reconciliations, 
               each_serializer: ReconciliationWithItemsSerializer,
               status: :ok
      end

      def create
        return render_date_error unless valid_date_range?

        if reconciliation_in_progress?
          return render json: { 
            error: 'Ya existe una reconciliación en proceso para este período' 
          }, status: :conflict
        end

        service = ReconciliationProcessorService.new(
          store: current_store,
          start_date: params[:start_date],
          end_date: params[:end_date],
          initiated_by: 'store_user'
        )

        service.call

        if service.valid?
          render json: { 
            message: 'Reconciliación finalizado correctamente',
          }, status: :created
        else
          render json: { 
            error: service.errors[:message] || 'Error al procesar la reconciliación'
          }, status: :unprocessable_entity
        end
      end

      private

      def valid_date_range?
        return false unless params[:start_date].present? && params[:end_date].present?
        
        begin
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          
          start_date <= end_date && 
            (end_date - start_date).to_i <= 90 && 
            end_date <= Date.today
        rescue ArgumentError
          false
        end
      end

      def render_date_error
        render json: { 
          error: 'Fechas inválidas. Verifique el formato (YYYY-MM-DD) y el rango (máximo 3 meses)' 
        }, status: :unprocessable_entity
      end

      def reconciliation_in_progress?
        current_store.reconciliations
                    .where(status: 'in_progress')
                    .where('start_date <= ? AND end_date >= ?', 
                           params[:end_date], 
                           params[:start_date])
                    .exists?
      end
    end
  end
end