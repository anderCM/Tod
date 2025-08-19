# frozen_string_literal: true

class ReconciliationProcessorService < BaseService
  attr_reader :detailed_summary

  def initialize(store: nil, start_date:, end_date:, initiated_by: 'system', csv_file: nil)
    @store = store
    @start_date = start_date.to_date
    @end_date = end_date.to_date
    @initiated_by = initiated_by
    @csv_file = csv_file
    @detailed_summary = []
  end

  def call
    service_instance = create_service_instance(
      store: @store,
      csv_file: @csv_file,
      start_date: @start_date,
      end_date: @end_date,
      initiated_by: @initiated_by
    )

    service_instance.call

    raise StandardError, service_instance.errors[:message] unless service_instance.valid?

    reconciliations = extract_reconciliations(service_instance)

    @detailed_summary = build_detailed_summaries(
      reconciliations: reconciliations,
      service_instance: service_instance,
      start_date: @start_date,
      end_date: @end_date,
      store: @store
    )

    set_as_valid!
  rescue => e
    set_error_message(e.message)
    set_as_invalid!
  end

  private

  def create_service_instance(store:, csv_file:, start_date:, end_date:, initiated_by:)
    if csv_file.present?
      ReconciliationServices::CsvReconciliationService.new(
        start_date: start_date,
        end_date: end_date,
        csv_file: csv_file,
        initiated_by: initiated_by
      )
    else
      raise ArgumentError, "Store is required for system reconciliation" unless store

      ReconciliationServices::SystemReconciliationService.new(
        store: store,
        start_date: start_date,
        end_date: end_date,
        initiated_by: initiated_by
      )
    end
  end

  def extract_reconciliations(service_instance)
    if service_instance.respond_to?(:reconciliations_by_store) && service_instance.reconciliations_by_store.any?
      service_instance.reconciliations_by_store.values
    elsif service_instance.respond_to?(:reconciliation)
      [service_instance.reconciliation]
    else
      []
    end
  end

  def build_detailed_summaries(reconciliations:, service_instance:, start_date:, end_date:, store:)
    reconciliations.map do |reconciliation|
      build_single_detailed_summary(
        reconciliation: reconciliation,
        service_instance: service_instance,
        start_date: start_date,
        end_date: end_date,
        store: store
      )
    end
  end

  def build_single_detailed_summary(reconciliation:, service_instance:, start_date:, end_date:, store:)
    base_summary = {
      id: reconciliation.id,
      type: reconciliation.reconciliation_type,
      status: reconciliation.status,
      period: {
        start_date: start_date,
        end_date: end_date
      },
      totals: extract_totals(reconciliation, service_instance),
      created_at: reconciliation.created_at,
      completed_at: reconciliation.completed_at
    }

    add_type_specific_details(
      base_summary: base_summary,
      reconciliation: reconciliation,
      service_instance: service_instance,
      store: store
    )
  end

  def extract_totals(reconciliation, service_instance)
    if service_instance.respond_to?(:reconciliations_by_store) && 
       service_instance.reconciliations_by_store.key?(reconciliation.store_id)
      {
        matched_count: reconciliation.matched_items.count,
        unmatched_count: reconciliation.unmatched_items.count,
        total_amount_matched: calculate_reconciliation_amount_matched(reconciliation),
        total_amount_unmatched: calculate_reconciliation_amount_unmatched(reconciliation)
      }
    else
      {
        matched_count: service_instance.matched_count || 0,
        unmatched_count: service_instance.unmatched_count || 0,
        total_amount_matched: service_instance.total_amount_matched || 0,
        total_amount_unmatched: service_instance.total_amount_unmatched || 0
      }
    end
  end

  def add_type_specific_details(base_summary:, reconciliation:, service_instance:, store:)
    case reconciliation.reconciliation_type
    when 'file_import'
      base_summary[:file_details] = extract_file_import_details(service_instance)
      if reconciliation.store
        base_summary[:store_details] = {
          store_id: reconciliation.store.id,
          store_name: reconciliation.store.name
        }
      end
    when 'automatic', 'manual'
      base_summary[:store_details] = extract_system_reconciliation_details(
        service_instance: service_instance,
        store: store
      )
    end

    base_summary
  end

  def extract_file_import_details(service_instance)
    return {} unless service_instance.respond_to?(:reconciliation_file)
    
    file = service_instance.reconciliation_file
    return {} unless file

    {
      file_name: file.file_name,
      file_type: file.file_type,
      file_status: file.status,
      processed_rows: service_instance.processed_rows
    }
  end

  def extract_system_reconciliation_details(service_instance:, store:)
    return {} unless store

    {
      store_id: store.id,
      store_name: store.name,
      sales_analyzed: count_if_present(service_instance, :sales),
      transactions_analyzed: count_if_present(service_instance, :transactions),
      unmatched_sales: count_if_present(service_instance, :unmatched_sales),
      unmatched_transactions: count_if_present(service_instance, :unmatched_transactions)
    }
  end

  def calculate_reconciliation_amount_matched(reconciliation)
    reconciliation.matched_items.sum do |item|
      notes = JSON.parse(item.notes) rescue {}
      notes['amount'] || notes['csv_amount'] || 0
    end
  end

  def calculate_reconciliation_amount_unmatched(reconciliation)
    reconciliation.unmatched_items.sum do |item|
      notes = JSON.parse(item.notes) rescue {}
      notes['amount'] || notes['csv_amount'] || 0
    end
  end

  def count_if_present(service_instance, attribute)
    return 0 unless service_instance.respond_to?(attribute)
    
    collection = service_instance.send(attribute)
    collection&.count || 0
  end
end
