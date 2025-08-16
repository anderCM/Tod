# frozen_string_literal: true

class StoresController < ApplicationController
  before_action :set_store, only: [:show, :edit, :update, :destroy, :transactions, :summary]

  def index
    @stores = Store.all
    render json: @stores
  end

  def show
    render json: @store
  end

  def create
    @store = Store.new(store_params)

    if @store.save
      render json: @store, status: :created
    else
      render json: { errors: @store.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @store.update(store_params)
      render json: @store
    else
      render json: { errors: @store.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @store.destroy
    head :no_content
  end

  def transactions
    @transactions = @store.transactions.includes(:customer, :wallet)
      .order(transaction_date: :desc)

    @transactions = @transactions.where(status: params[:status]) if params[:status].present?
    @transactions = @transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?

    if params[:start_date].present? && params[:end_date].present?
      @transactions = @transactions.where(transaction_date: params[:start_date]..params[:end_date])
    end

    render json: @transactions, status: :ok
  end

  def summary
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current

    @summary = @store.transaction_summary(start_date, end_date)
    @transactions = @store.transactions_in_period(start_date, end_date)

    @wallet_balance = @store.wallet_balance
    @pending_amount = @store.transactions.where(status: "pending").sum(:amount)
    @failed_amount = @store.transactions.where(status: "failed").sum(:amount)
    
    render json: {
      summary: @summary,
      transactions: @transactions,
      wallet_balance: @wallet_balance,
      pending_amount: @pending_amount,
      failed_amount: @failed_amount
    }
  end

  private

  def set_store
    @store = Store.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :description, :status, :tax_id, :address, :phone, :email)
  end
end
