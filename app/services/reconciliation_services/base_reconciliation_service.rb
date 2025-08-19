# frozen_string_literal: true

module ReconciliationServices
  class BaseReconciliationService < ::BaseService
    attr_reader :reconciliation, :matched_count, :unmatched_count, 
                :total_amount_matched, :total_amount_unmatched

    def initialize(store:, start_date:, end_date:, initiated_by: 'system', options: {})
      @store = store
      @start_date = start_date.to_date
      @end_date = end_date.to_date
      @initiated_by = initiated_by
      @options = options
      @reconciliation = nil
      @matched_count = 0
      @unmatched_count = 0
      @total_amount_matched = 0
      @total_amount_unmatched = 0
    end

    def call
      ActiveRecord::Base.transaction do
        @reconciliation = create_reconciliation(@store, @start_date, @end_date, reconciliation_type, @initiated_by)

        load_source_data
        load_target_data
        perform_matching
        verify_balances(@store)

        @matched_count = @reconciliation.matched_items.count
        @unmatched_count = @reconciliation.unmatched_items.count
        @total_amount_matched = calculate_total_amount_matched(@reconciliation)
        @total_amount_unmatched = calculate_total_amount_unmatched(@reconciliation)

        reconciliation_status = determine_final_status(@unmatched_count)
        update_reconciliation_status(reconciliation, reconciliation_status, @matched_count, @unmatched_count, @total_amount_matched, @total_amount_unmatched)

        set_as_valid!
      end
    rescue => e
      handle_error(@reconciliation, e)
      set_as_invalid!
    end

    private

    def load_source_data
      raise NotImplementedError, "#{self.class} must implement #load_source_data"
    end

    def load_target_data
      raise NotImplementedError, "#{self.class} must implement #load_target_data"
    end

    def perform_matching
      raise NotImplementedError, "#{self.class} must implement #perform_matching"
    end

    def reconciliation_type
      raise NotImplementedError, "#{self.class} must implement #reconciliation_type"
    end

    # Checks balance for all wallets in store 
    #   and creates reconciliation items for any inconsistencies found
    #
    # @return [void]
    def verify_balances(store)
      store.wallets.each do |wallet|
        consistency_check = wallet.balance_consistency_check
        next if consistency_check[:is_consistent]

        create_reconciliation_item(
          source: wallet,
          target: nil,
          status: 'disputed',
          amount_difference: consistency_check[:difference],
          notes: "Balance inconsistency detected"
        )
      end
    end

    # Creates a reconciliation item every reconciliation process with a in_progress status
    #
    # @param store [Store] the store being reconciled
    # @param start_date [Date] the start date of the reconciliation period
    # @param end_date [Date] the end date of the reconciliation period
    # @param reconciliation_type [String] the type of reconciliation
    # @param initiated_by [String] who initiated the reconciliation
    #
    # @return [Reconciliation] the created reconciliation record
    def create_reconciliation(store, start_date, end_date, reconciliation_type, initiated_by)
      Reconciliation.create!(
        store:,
        start_date:,
        end_date:,
        status: 'in_progress',
        reconciliation_type:,
        initiated_by:
      )
    end

    # Creates a reconciliation item for every related source and target
    #
    # @param source [Object] the source object (e.g., Sale, Transaction)
    # @param target [Object] the target object (e.g., Sale, Transaction)
    # @param status [String] the match status (e.g., matched, unmatched)
    # @param amount_difference [Float] the difference in amounts if applicable
    # @param notes [String] additional notes for the reconciliation item
    #
    # @return [ReconciliationItem] the created reconciliation item record
    def create_reconciliation_item(source:, target:, status:, amount_difference: 0, notes: nil)
      rule_applied = nil
      if notes.is_a?(String)
        begin
          parsed_notes = JSON.parse(notes)
          rule_applied = parsed_notes['rule_applied']
        rescue
          # If it's not JSON, just use the original notes(nil)
        end
      end

      ReconciliationItem.create!(
        reconciliation: @reconciliation,
        source:,
        target:,
        match_status: status,
        match_rule_applied: rule_applied,
        amount_difference:,
        notes:
      )
    end

    # Retrieves the total amount matched from matched items
    #
    # @param reconciliation [Reconciliation] the reconciliation record
    #
    # @return [Float] the total amount matched
    def calculate_total_amount_matched(reconciliation)
      reconciliation.matched_items.sum do |item|
        extract_amount_from_item(item)
      end
    end

    # Retrieves the total amount unmatched from unmatched items
    #
    # @param reconciliation [Reconciliation] the reconciliation record
    #
    # @return [Float] the total amount unmatched
    def calculate_total_amount_unmatched(reconciliation)
      reconciliation.unmatched_items.sum do |item|
        extract_amount_from_item(item)
      end
    end

    # Extracts the amount from a reconciliation item based on its source type
    #
    # @param item [ReconciliationItem] the reconciliation item
    #
    # @return [Float] the extracted amount
    def extract_amount_from_item(item)
      case item.source_type
      when 'Sale'
        item.source&.total_amount || 0
      when 'Transaction'
        item.source&.amount || 0
      when 'ReconciliationFile'
        parse_amount_from_notes(item.notes) || 0
      else
        0
      end
    end

    # Retrieves the amount from notes in a reconciliation item
    #
    # @param notes [String] the notes field from the reconciliation item
    #
    # @return [Float] the parsed amount, or 0 if parsing fails
    def parse_amount_from_notes(notes)
      return 0 if notes.blank?

      parsed = JSON.parse(notes) rescue {}
      parsed['amount'] || parsed['transfer_amount'] || 0
    end

    # Updates the reconciliation status and totals
    #
    # @param reconciliation [Reconciliation] the reconciliation record
    # @param reconciliation_status [String] the new status of the reconciliation
    # @param total_matched [Integer] the total number of matched items
    # @param total_unmatched [Integer] the total number of unmatched items
    # @param total_amount_matched [Float] the total amount matched
    # @param total_amount_unmatched [Float] the total amount unmatched
    #
    # @return [void]
    def update_reconciliation_status(reconciliation, reconciliation_status, total_matched, total_unmatched, total_amount_matched, total_amount_unmatched)
      reconciliation.update!(
        status: reconciliation_status,
        completed_at: Time.current,
        total_matched:,
        total_unmatched:,
        total_amount_matched:,
        total_amount_unmatched:
      )
    end

    # Returns the final status of the reconciliation based on unmatched count
    #
    # @param total_unmatched [Integer] the total number of unmatched items
    #
    # @return [String] the final status of the reconciliation
    def determine_final_status(total_unmatched)
      return 'completed' if total_unmatched == 0

      return 'with_errors' if total_unmatched > 0

      'failed'
    end

    # Stores the error message in the service context and
    #  updates the reconciliation status to failed
    #
    # @param reconciliation [Reconciliation] the reconciliation record
    # @param error [StandardError] the error that occurred
    #
    # @return [void]
    def handle_error(reconciliation, error)
      set_error_message(error.message)
      reconciliation&.update(status: 'failed', completed_at: Time.current)
    end

    # Memoizes active reconciliation rules for the store
    #
    # @return [Array<Hash>] the list of active reconciliation rules
    def load_rules
      return @rules if @rules

      service = StoreReconciliationRules::GetRulesService.new(store: @store)
      service.call

      @rules = service.rules.select { |rule| rule[:active] }
    end

    # Applies matching rules between source and target objects
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    #
    # @return [Hash] the result of the matching attempt, including:
    def apply_matching_rules(source, target)
      rules = load_rules

      rules.each do |rule|
        match_result = apply_rule_by_type(source, target, rule)

        if match_result[:matched]
          return {
            matched: true,
            rule_applied: rule[:name],
            rule_type: rule[:rule_type]
          }
        end
      end

      { matched: false, rule_applied: nil, rule_type: nil }
    end

    # Applies a specific rule type between source and target
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    # @param rule [Hash] the rule to apply
    #
    # @return [Hash] the result of the rule application, including:
    def apply_rule_by_type(source, target, rule)
      case rule[:rule_type]
      when 'exact'
        apply_exact_match_rule(source, target)
      when 'date'
        apply_date_tolerance_rule(source, target, rule[:tolerance_value])
      when 'percentage'
        apply_percentage_tolerance_rule(source, target, rule[:tolerance_value])
      when 'amount'
        apply_amount_tolerance_rule(source, target, rule[:tolerance_value])
      else
        { matched: false }
      end
    end

    # Extracts match rule
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    #
    # @return [Hash] the result of the exact match rule application
    def apply_exact_match_rule(source, target)
      amounts_match = source_amount(source) == target_amount(target)
      dates_match = source_date(source) == target_date(target)

      { matched: amounts_match && dates_match }
    end

    # Applies a date tolerance rule between source and target
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    # @param tolerance_days [Integer] the number of days tolerance for date matching
    #
    # @return [Hash] the result of the date tolerance rule application
    def apply_date_tolerance_rule(source, target, tolerance_days)
      amounts_match = source_amount(source) == target_amount(target)
      return { matched: false } unless amounts_match

      date_diff = (source_date(source) - target_date(target)).abs

      { matched: date_diff <= tolerance_days }
    end

    # Applies a percentage tolerance rule between source and target
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    # @param tolerance_days [Integer] the number of days tolerance for date matching
    #
    # @return [Hash] the result of the date tolerance rule application
    def apply_percentage_tolerance_rule(source, target, tolerance_percentage)
      source_amt = source_amount(source)
      target_amt = target_amount(target)

      return { matched: false } if source_amt == 0

      percentage_diff = ((source_amt - target_amt).abs / source_amt * 100)

      { matched: percentage_diff <= tolerance_percentage }
    end

    # Applies an amount tolerance rule between source and target
    #
    # @param source [Object] the source object
    # @param target [Object] the target object
    # @param tolerance_days [Integer] the number of days tolerance for date matching
    #
    # @return [Hash] the result of the date tolerance rule application
    def apply_amount_tolerance_rule(source, target, tolerance_amount)
      amount_diff = (source_amount(source) - target_amount(target)).abs

      { matched: amount_diff <= tolerance_amount }
    end

    # Returns the amount of the source object
    #
    # @param source [Object] the source object
    #
    # @return [Float] the amount of the source object
    def source_amount(source)
      case source
      when Sale then source.total_amount
      when Transaction then source.amount
      else 0
      end
    end

    # Returns the amount of the target object
    #
    # @param target [Object] the target object
    #
    # @return [Float] the amount of the target object
    def target_amount(target)
      case target
      when Sale then target.total_amount
      when Transaction then target.amount
      else 0
      end
    end

    # Returns the date of the source object
    #
    # @param source [Object] the source object
    #
    # @return [Float] the amount of the source object
    def source_date(source)
      case source
      when Sale then source.sale_date.to_date
      when Transaction then source.transaction_date.to_date
      else @start_date
      end
    end

    # Returns the date of the target object
    #
    # @param target [Object] the target object
    #
    # @return [Float] the amount of the target object
    def target_date(target)
      case target
      when Sale then target.sale_date.to_date
      when Transaction then target.transaction_date.to_date
      else @start_date
      end
    end
  end
end
