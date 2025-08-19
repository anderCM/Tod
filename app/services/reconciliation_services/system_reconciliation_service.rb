# frozen_string_literal: true

module ReconciliationServices
  class SystemReconciliationService < BaseReconciliationService
    attr_reader :sales, :transactions, :unmatched_sales, :unmatched_transactions

    def call
      @unmatched_sales = []
      @unmatched_transactions = []
      super
    end

    private

    # Default reconciliation type for system reconciliation
    def reconciliation_type
      'automatic'
    end

    # Loads sales data as the source data for reconciliation
    #
    # @return [void]
    def load_source_data
      @sales = @store.sales
        .where(sale_date: @start_date..@end_date)
        .includes(:customer)
    end

    # Loads transactions data as the target data for reconciliation
    #
    # @return [void]
    def load_target_data
      @transactions = @store.transactions
        .where(transaction_date: @start_date.beginning_of_day..@end_date.end_of_day)
        .where(transaction_type: ['payment', 'refund'])
        .includes(:customer, :wallet)
    end

    # Execute the matching process between sales and transactions
    #
    # @return [void]
    def perform_matching
      match_sales_to_transactions(@sales)
      identify_unmatched_transactions
      verify_wallet_transactions
    end

    # Finds a matching between sales and transactions based on predefined rules
    def match_sales_to_transactions(sales)
      sales.each do |sale|
        @last_rule_applied = nil

        transaction = find_matching_transaction(sale)

        if transaction
          create_reconciliation_item(
            source: sale,
            target: transaction,
            status: 'matched',
            amount_difference: calculate_amount_difference(sale, transaction),
            notes: build_match_notes(sale, transaction, {
              rule_applied: @last_rule_applied
            })
          )

          @matched_transaction_ids ||= []
          @matched_transaction_ids << transaction.id
          next
        end

        @unmatched_sales << sale
        create_reconciliation_item(
          source: sale,
          target: nil,
          status: 'unmatched',
          notes: "No matching transaction found for sale ##{sale.sale_number}"
        )
      end
    end

    # Finds a matching transaction for a given sale based on rules
    #
    # @param sale [Sale] the sale to find a matching transaction for
    #
    # @return [Transaction, nil] the matching transaction or nil if none found
    def find_matching_transaction(sale)
      rules = load_rules
      return nil if rules.empty?

      potential_matches = @transactions.select do |transaction|
        next if @matched_transaction_ids&.include?(transaction.id)

        transaction.customer_id == sale.customer_id &&
          transaction.transaction_type == 'payment' &&
          transaction.status == 'completed'
      end

      rules.each do |rule|
        potential_matches.each do |transaction|
          debugger
          match_result = apply_rule_by_type(sale, transaction, rule)

          if match_result[:matched]
            @last_rule_applied = rule[:name]
            return transaction
          end
        end
      end

      nil # No match found with any rule
    end

    # Finds transactions that were not matched to any sale
    #
    # @return [void]
    def identify_unmatched_transactions
      unmatched = @transactions.reject do |transaction|
        @matched_transaction_ids&.include?(transaction.id)
      end

      unmatched.each do |transaction|
        @unmatched_transactions << transaction

        create_reconciliation_item(
          source: transaction,
          target: nil,
          status: 'unmatched',
          notes: build_unmatched_transaction_notes(transaction)
        )
      end
    end

    # Verifies the balances of wallets involved in the transactions
    #
    # @return [void]
    def verify_wallet_transactions
      customer_wallets = @transactions.map(&:wallet).uniq.compact

      customer_wallets.each do |wallet|
        verify_wallet_balance(wallet)
      end

      @store.wallets.each do |wallet|
        verify_wallet_balance(wallet)
      end
    end

    # Verifies the balance of a specific wallet and creates reconciliation items for discrepancies
    #
    # @param wallet [Wallet] the wallet to verify
    #
    # @return [void]
    def verify_wallet_balance(wallet)
      period_transactions = wallet.transactions_in_period(@start_date, @end_date)
      expected_change = period_transactions.completed.sum do |t|
        if wallet.wallet_type == 'customer'
          t.transaction_type == 'payment' ? -t.amount : t.amount
        else
          t.transaction_type == 'payment' ? t.amount : -t.amount
        end
      end

      consistency_check = wallet.balance_consistency_check

      if !consistency_check[:is_consistent]
        create_reconciliation_item(
          source: wallet,
          target: nil,
          status: 'disputed',
          amount_difference: consistency_check[:difference],
          notes: build_wallet_discrepancy_notes(wallet, consistency_check)
        )
      end
    end

    # Calculates the amount difference between a sale and its matching transaction
    #
    # @param sale [Sale] the sale
    # @param transaction [Transaction] the matching transaction
    #
    # @return [Float] the amount difference
    def calculate_amount_difference(sale, transaction)
      return 0 unless transaction

      sale.total_amount - transaction.amount
    end

    # Creates notes for a matched sale and transaction
    #   These notes are only for internal reference and debugging
    #
    # @param sale [Sale] the sale
    # @param transaction [Transaction] the matching transaction
    # @param result [Hash] additional result info such as rule applied
    #
    # @return [String] JSON string with match details
    def build_match_notes(sale, transaction, result)
      {
        sale_number: sale.sale_number,
        transaction_reference: transaction.reference,
        rule_applied: result[:rule_applied],
        sale_date: sale.sale_date,
        transaction_date: transaction.transaction_date
      }.to_json
    end

    # Creates notes for an unmatched sale and transaction
    #   These notes are only for internal reference and debugging
    #
    # @param sale [Sale] the sale
    # @param transaction [Transaction] the matching transaction
    # @param result [Hash] additional result info such as rule applied
    #
    # @return [String] JSON string with match details
    def build_unmatched_transaction_notes(transaction)
      {
        transaction_reference: transaction.reference,
        transaction_type: transaction.transaction_type,
        amount: transaction.amount,
        customer: transaction.customer.name,
        date: transaction.transaction_date,
        status: transaction.status
      }.to_json
    end

    # Creates notes for wallet discrepancies
    #  These notes are only for internal reference and debugging
    #
    # @param wallet [Wallet] the wallet
    # @param consistency_check [Hash] the result of the balance consistency check
    #
    # @return [String] JSON string with discrepancy details
    def build_wallet_discrepancy_notes(wallet, consistency_check)
      {
        wallet_type: wallet.wallet_type,
        owner: wallet.owner_type == 'Store' ? wallet.owner.name : wallet.owner.name,
        current_balance: consistency_check[:current_balance],
        expected_balance: consistency_check[:expected_balance],
        difference: consistency_check[:difference]
      }.to_json
    end
  end
end
