# frozen_string_literal: true

module StoreReconciliationRules
  class UpdateRulesService < BaseService
    attr_reader :updated_rules

    # Creates or updates reconciliation rules for a specific store based on provided parameters
    #
    # @param store [Store] the store for which to update rules
    # @param rules_params [Array<Hash>] an array of hashes containing rule parameters
    def initialize(store:, rules_params:)
      @store = store
      @rules_params = rules_params
      @updated_rules = []
      @rules_errors = []
    end

    def call
      ActiveRecord::Base.transaction do
        process_rules(@store, @rules_params)

        if @rules_errors.any?
          set_error_message(@rules_errors.join(', '))
          set_as_invalid!
          raise ActiveRecord::Rollback
        else
          set_as_valid!
        end
      end
    rescue StandardError => e
      set_error_message("Error actualizando reglas: #{e.message}")
      set_as_invalid!
    end

    private

    # Memoizes the default reconciliation rules to avoid multiple database queries
    #   Does not need index or any other strategy because there are only a few rules
    #
    # @return [Array<ReconciliationRule>] the default reconciliation rules
    def default_rules
      @default_rules ||= ReconciliationRule.all
    end

    # Proceeses each rule parameter, creating or updating the store's reconciliation rules
    #
    # @param store [Store] the store for which to process rules
    # @param rules_params [Array<Hash>] an array of hashes containing rule parameters
    #
    # @return [void]
    def process_rules(store, rules_params)
      rules_params.each do |rule_param|
        process_single_rule(store, rule_param)
      end
    end

    # Processes a single rule parameter, creating or updating the store's reconciliation rule
    #
    # @param store [Store] the store for which to process the rule
    # @param rule_param [Hash] a hash containing the rule parameters
    #
    # @return [void]
    def process_single_rule(store, rule_param)
      rule = default_rules.find { |default_rule| default_rule.id == rule_param[:rule_id].to_i }
      unless rule
        add_error("Regla no encontrada: ID #{rule_param[:rule_id]}")
        return
      end

      create_or_update_store_rule(store, rule, rule_param)
    end

    # Creates or updates the store's reconciliation rule based on the provided parameters
    #
    # @param store [Store] the store for which to create or update the rule
    # @param rule [ReconciliationRule] the reconciliation rule to be created or updated
    # @param rule_param [Hash] a hash containing the rule parameters
    #
    # @return [void]
    def create_or_update_store_rule(store, rule, rule_param)
      store_rule = store.store_reconciliation_rules.find_or_initialize_by(reconciliation_rule_id: rule.id)

      store_rule.assign_attributes(
        tolerance_value: rule_param[:tolerance_value].to_f,
        priority: rule_param[:priority].to_i,
        active: rule_param[:active],
      )

      if store_rule.save
        @updated_rules << store_rule
        return
      end

      add_error("Regla #{rule.name}: #{store_rule.errors.full_messages.join(', ')}")
    end

    # Adds an error message to the rules errors array
    #
    # @param message [String] the error message to be added
    #
    # @return [void]
    def add_error(message)
      @rules_errors << message
    end
  end
end
