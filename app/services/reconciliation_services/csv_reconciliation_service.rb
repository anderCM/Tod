# frozen_string_literal: true

require 'csv'

module ReconciliationServices
  class CsvReconciliationService < BaseReconciliationService
    attr_reader :csv_file, :csv_data, :reconciliation_file, :processed_rows, :reconciliations_by_store

    def initialize(store: nil, start_date:, end_date:, csv_file:, initiated_by: 'admin', options: {})
      super(store:, start_date:, end_date:, initiated_by:, options:)
      @csv_file = csv_file
      @csv_data = []
      @processed_rows = 0
      @reconciliation_file = nil
      @reconciliations_by_store = {}
      @store_data_cache = {}
      @stores_cache = {}
    end

    def call
      ActiveRecord::Base.transaction do
        load_source_data
        perform_matching
        calculate_totals_summary

        set_as_valid!
      end
    rescue => e
      handle_error(nil, e)
      set_as_invalid!
    end

    # Returns summary of all reconciliations by store
    #
    # @return [Hash] summary with details per store
    def summary_by_store
      return {} unless @reconciliations_by_store

      @reconciliations_by_store.map do |store_id, reconciliation|
        store = @stores_cache[store_id]
        {
          store_id: store_id,
          store_name: store&.name,
          reconciliation_id: reconciliation.id,
          matched_count: reconciliation.matched_items.count,
          unmatched_count: reconciliation.unmatched_items.count,
          total_amount_matched: calculate_total_amount_matched(reconciliation),
          total_amount_unmatched: calculate_total_amount_unmatched(reconciliation),
          status: reconciliation.status
        }
      end
    end

    private

    # Default reconciliation type for file reconciliation
    def reconciliation_type
      'file_import'
    end

    # Loads the file and prepares data for reconciliation
    #
    # @return [void]
    def load_source_data
      parse_csv_file
      preload_stores
    end

    # Executes the matching process between file data and store transactions
    #
    # @return [void]
    def perform_matching
      csv_by_store = @csv_data.group_by { |row| row[:tienda_id] }

      csv_by_store.each do |store_id, store_rows|
        store = @stores_cache[store_id]
        next unless store

        create_store_reconciliation(store)
        if @reconciliation_file.nil?
          create_reconciliation_file(@reconciliations_by_store[store.id])
        end

        load_store_target_data(store)
        store_rows.each do |row|
          process_csv_row(row, store)
          @processed_rows += 1
        end
      end

      update_reconciliation_file_status
      finalize_reconciliations
    end

    # Preload all stores mentioned in CSV to avoid N+1
    def preload_stores
      store_ids = @csv_data.map { |row| row[:tienda_id] }.uniq
      stores = Store.where(id: store_ids).includes(:wallets, :sales, :transactions)

      stores.each do |store|
        @stores_cache[store.id] = store
      end

      missing_ids = store_ids - @stores_cache.keys
      if missing_ids.any?
        Rails.logger.warn "CSV contains unknown store IDs: #{missing_ids.join(', ')}"
      end
    end

    # Creates and initializes the reconciliation file
    #
    # @return [void]
    def create_reconciliation_file(reconciliation)
      @reconciliation_file = ReconciliationFile.create!(
        reconciliation: reconciliation,
        file_name: extract_file_name,
        file_type: 'csv',
        status: 'processing'
      )

      @reconciliation_file.file.attach(@csv_file) if @csv_file.respond_to?(:read)
    end

    # Gets the file name from the uploaded file
    #
    # @return [String] the name of the file
    def extract_file_name
      return @csv_file.original_filename if @csv_file.respond_to?(:original_filename)

      return File.basename(@csv_file.path) if @csv_file.respond_to?(:path)

      "csv_import_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    end

    # Extracts and parses the CSV file content
    #
    # @return [void]
    def parse_csv_file
      csv_content = read_csv_content

      @csv_data = CSV.parse(csv_content, headers: true, header_converters: :symbol).map do |row|
        {
          fecha_transferencia: Date.parse(row[:fecha_transferencia]),
          tienda_id: row[:tienda_id].to_i,
          tienda_nombre: row[:tienda_nombre],
          tienda_tax_id: row[:tienda_tax_id],
          total_ventas_dia: row[:total_ventas_dia].to_f,
          cantidad_transacciones: row[:cantidad_transacciones].to_i,
          monto_transferencia: row[:monto_transferencia].to_f,
          referencia_transferencia: row[:referencia_transferencia],
          estado_transferencia: row[:estado_transferencia],
          observaciones: row[:observaciones]
        }
      end

      @csv_data.select! do |row|
        row[:fecha_transferencia] >= @start_date && row[:fecha_transferencia] <= @end_date
      end
    rescue CSV::MalformedCSVError => e
      raise StandardError, "Invalid CSV format: #{e.message}"
    rescue => e
      raise StandardError, "Error parsing CSV: #{e.message}"
    end

    # Reads the entire content of the CSV file
    #
    # @return [String] the content of the CSV file
    def read_csv_content
      if @csv_file.respond_to?(:read)
        @csv_file.read
      elsif @csv_file.is_a?(String) && File.exist?(@csv_file)
        File.read(@csv_file)
      elsif @csv_file.is_a?(String)
        @csv_file
      else
        raise StandardError, "Unable to read CSV file"
      end
    end
  
    # Processes each row of the CSV file
    #
    # @param row [Hash] the CSV row data
    # @param store [Store] the store being processed
    #
    # @return [void]
    def process_csv_row(row, store)
      date = row[:fecha_transferencia]
      csv_total = row[:monto_transferencia]
      csv_transaction_count = row[:cantidad_transacciones]

      store_data = @store_data_cache[store.id]
      actual_transactions = store_data[:transactions][date] || []
      actual_sales = store_data[:sales][date] || []

      actual_transaction_total = actual_transactions.sum(&:amount)
      actual_sales_total = actual_sales.sum(&:total_amount)
      actual_count = actual_transactions.size

      amount_matches = (csv_total - actual_transaction_total).abs < 0.01
      count_matches = csv_transaction_count == actual_count

      # Only consider it matched if BOTH amount and count match
      match_status = if amount_matches && count_matches
                       'matched'
                     else
                       'unmatched'
                     end

      @reconciliation = @reconciliations_by_store[store.id]

      create_reconciliation_item(
        source: @reconciliation_file,
        target: store,
        status: match_status,
        amount_difference: csv_total - actual_transaction_total,
        notes: build_csv_row_notes(row, actual_transactions, actual_sales)
      )
    end

    # Builds notes for a CSV row reconciliation item
    #
    # @param csv_row [Hash] the CSV row data
    # @param transactions [Array<Transaction>] the actual transactions for the date
    # @param sales [Array<Sale>] the actual sales for the date
    #
    # @return [String] JSON formatted notes
    def build_csv_row_notes(csv_row, transactions, sales)
      {
        csv_reference: csv_row[:referencia_transferencia],
        csv_date: csv_row[:fecha_transferencia],
        csv_amount: csv_row[:monto_transferencia],
        csv_count: csv_row[:cantidad_transacciones],
        actual_amount: transactions.sum(&:amount),
        actual_count: transactions.size,
        sales_total: sales.sum(&:total_amount),
        sales_count: sales.size,
        store_name: csv_row[:tienda_nombre],
        observations: csv_row[:observaciones],
        amount: csv_row[:monto_transferencia]
      }.to_json
    end

    # Updates the reconciliation file status after processing
    #
    # @return [void]
    def update_reconciliation_file_status
      @reconciliation_file.update!(
        status: 'completed'
      )
    rescue => e
      @reconciliation_file.update!(
        status: 'failed'
      )
      raise e
    end

    # Creates a reconciliation for a specific store
    # @param store [Store] the store to create reconciliation for
    #
    # @return [void]
    def create_store_reconciliation(store)
      reconciliation = Reconciliation.create!(
        store: store,
        start_date: @start_date,
        end_date: @end_date,
        status: 'in_progress',
        reconciliation_type: reconciliation_type,
        initiated_by: @initiated_by
      )

      @reconciliations_by_store[store.id] = reconciliation
    end

    # Loads target data for a specific store
    #
    # @param store [Store] the store to load data for
    #
    # @return [void]
    def load_store_target_data(store)
      transactions = store.transactions
        .where(transaction_date: @start_date.beginning_of_day..@end_date.end_of_day)
        .where(status: 'completed')
        .group_by { |t| t.transaction_date.to_date }

      sales = store.sales
        .where(sale_date: @start_date..@end_date)
        .where(status: 'completed')
        .group_by { |s| s.sale_date.to_date }

      @store_data_cache[store.id] = {
        transactions: transactions,
        sales: sales
      }
    end

    # Finalizes all reconciliations created during the process
    def finalize_reconciliations
      @reconciliations_by_store.each do |store_id, reconciliation|
        matched_count = reconciliation.matched_items.count
        unmatched_count = reconciliation.unmatched_items.count
        total_amount_matched = calculate_total_amount_matched(reconciliation)
        total_amount_unmatched = calculate_total_amount_unmatched(reconciliation)

        status = determine_final_status(unmatched_count)

        reconciliation.update!(
          status: status,
          completed_at: Time.current,
          total_matched: matched_count,
          total_unmatched: unmatched_count,
          total_amount_matched: total_amount_matched,
          total_amount_unmatched: total_amount_unmatched
        )
      end
    end

    def handle_error(reconciliation, error)
      super(reconciliation, error)
      @reconciliations_by_store.values.each do |r|
        r.update(status: 'failed', completed_at: Time.current)
      end
    end

    # Calculates totals summary across all stores
    #
    # @return [void]
    def calculate_totals_summary
      if @reconciliations_by_store.any?
        # Sum totals from all store reconciliations
        @matched_count = 0
        @unmatched_count = 0
        @total_amount_matched = 0.0
        @total_amount_unmatched = 0.0

        @reconciliations_by_store.each do |store_id, reconciliation|
          @matched_count += reconciliation.matched_items.count
          @unmatched_count += reconciliation.unmatched_items.count
          @total_amount_matched += calculate_total_amount_matched(reconciliation)
          @total_amount_unmatched += calculate_total_amount_unmatched(reconciliation)
        end

        # For compatibility, set the first reconciliation as the main one
        # but the totals now reflect ALL stores
        @reconciliation = @reconciliations_by_store.values.first
      else
        @matched_count = 0
        @unmatched_count = 0
        @total_amount_matched = 0
        @total_amount_unmatched = 0
      end
    end
  end
end
