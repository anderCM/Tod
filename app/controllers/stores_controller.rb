# frozen_string_literal: true

class StoresController < ApplicationController
  before_action :set_store, only: [:show, :edit, :update, :destroy, :transactions, :summary]

  def index
    @stores = Store.all
  end

  def show
  end

  def new
    @store = Store.new
  end

  def edit
  end

  def create
    @store = Store.new(store_params)

    if @store.save
      redirect_to(@store, notice: "Tienda creada exitosamente.")
    else
      render(:new, status: :unprocessable_entity)
    end
  end

  def update
    if @store.update(store_params)
      redirect_to(@store, notice: "Tienda actualizada exitosamente.")
    else
      render(:edit, status: :unprocessable_entity)
    end
  end

  def destroy
    @store.destroy
    redirect_to(stores_url, notice: "Tienda eliminada exitosamente.")
  end

  def transactions
    @transactions = @store.transactions.includes(:customer, :wallet)
      .order(transaction_date: :desc)

    @transactions = @transactions.where(status: params[:status]) if params[:status].present?
    @transactions = @transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?

    if params[:start_date].present? && params[:end_date].present?
      @transactions = @transactions.where(transaction_date: params[:start_date]..params[:end_date])
    end
  end

  def summary
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.current

    @summary = @store.transaction_summary(start_date, end_date)
    @transactions = @store.transactions_in_period(start_date, end_date)

    @wallet_balance = @store.wallet_balance
    @pending_amount = @store.transactions.where(status: "pending").sum(:amount)
    @failed_amount = @store.transactions.where(status: "failed").sum(:amount)
  end

  private

  def set_store
    @store = Store.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :description, :status, :tax_id, :address, :phone, :email)
  end
end
