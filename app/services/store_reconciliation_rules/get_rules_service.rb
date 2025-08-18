# frozen_string_literal: true

module StoreReconciliationRules
  class GetRulesService < BaseService
    attr_reader :rules

    # Retrieves reconciliation rules for a specific store or defaults if it has no custom rules yet
    #
    # @param store [Store] the store for which to retrieve rules
    def initialize(store:)
      @store = store
      @rules = []
    end

    def call
      @rules = fetch_rules_with_values
      set_as_valid!
    rescue StandardError => e
      set_error_message("Error obteniendo reglas: #{e.message}")
      set_as_invalid!
    end
 
    private

    # Retrieves all active reconciliation rules, merging them with store-specific values
    #
    # @return [Array<Hash>] an array of hashes containing reconciliation rules with store-specific values
    def fetch_rules_with_values
      ReconciliationRule.active.by_priority.map do |rule|
        store_rule = store_rules.find { |store_rule| store_rule.reconciliation_rule_id == rule.id }
        build_rule_hash(rule, store_rule)
      end
    end

    # Memmoizes the store's reconciliation rules to avoid multiple database queries
    #
    # @return [Array<StoreReconciliationRule, nil>] the store's reconciliation rules
    #   or nil if the store has no custom rules
    def store_rules
      @store_rules ||= @store.store_reconciliation_rules
    end

    # Builds a hash representation of a reconciliation rule with its store-specific values
    #
    # @param rule [ReconciliationRule] the reconciliation rule
    # @param store_rule [StoreReconciliationRule, nil] the store-specific rule,
    #   or nil if the store has no custom rule for this reconciliation rule
    #
    # @return [Hash] a hash containing the rule's details and store-specific values
    def build_rule_hash(rule, store_rule)
      {
        id: rule.id,
        name: rule.name,
        description: rule.description,
        rule_type: rule.rule_type,
        tolerance_value: store_rule&.tolerance_value || rule.default_tolerance_value,
        priority: store_rule&.priority || rule.priority,
        active: store_rule&.active.nil? ? rule.active : store_rule.active
      }
    end
  end
end
