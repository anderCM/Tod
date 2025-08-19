# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReconciliationServices::SystemReconciliationService, type: :service do
  let(:store) { create(:store) }
  let(:customer) { create(:customer) }
  let(:customer_wallet) { create(:wallet, owner: customer, wallet_type: 'customer') }
  let(:store_wallet) { create(:wallet, owner: store, wallet_type: 'store') }
  let(:start_date) { 1.week.ago.to_date }
  let(:end_date) { Date.current }

  let(:service) do
    described_class.new(
      store: store,
      start_date: start_date,
      end_date: end_date,
      initiated_by: 'system'
    )
  end

  describe '#call' do
    context 'when there are perfect matches' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 3.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 100.00,
          transaction_date: 3.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:exact_rule) do
        create(:reconciliation_rule,
          name: 'Exact Match',
          rule_type: 'exact',
          priority: 1,
          active: true,
          default_tolerance_value: 0
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: exact_rule.id,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            }
          ])
      end

      it 'creates a successful reconciliation' do
        expect { service.call }.to change { Reconciliation.count }.by(1)
        expect(service.valid?).to be true
      end

      it 'matches the sale with the transaction' do
        service.call
        reconciliation = service.reconciliation
        
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.unmatched_items.count).to eq(0)
        expect(reconciliation.status).to eq('completed')
      end

      it 'records the correct match details' do
        service.call
        matched_item = service.reconciliation.matched_items.first
        
        expect(matched_item.source).to eq(sale)
        expect(matched_item.target).to eq(transaction)
        expect(matched_item.match_status).to eq('matched')
        expect(matched_item.amount_difference).to eq(0)
        expect(matched_item.match_rule_applied).to eq('Exact Match')
      end

      it 'calculates totals correctly' do
        service.call
        
        expect(service.matched_count).to eq(1)
        expect(service.unmatched_count).to eq(0)
        expect(service.total_amount_matched).to eq(100.00)
        expect(service.total_amount_unmatched).to eq(0)
      end
    end

    context 'when using date tolerance rules' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 150.00,
          sale_date: 5.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 150.00,
          transaction_date: 3.days.ago, # 2 days difference
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:date_rule) do
        create(:reconciliation_rule,
          name: 'Date Tolerance',
          rule_type: 'date',
          priority: 2,
          active: true,
          default_tolerance_value: 3 # 3 days tolerance
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: date_rule.id,
              name: 'Date Tolerance',
              rule_type: 'date',
              tolerance_value: 3,
              priority: 2,
              active: true
            }
          ])
      end

      it 'matches within date tolerance' do
        service.call
        reconciliation = service.reconciliation
        
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.matched_items.first.match_rule_applied).to eq('Date Tolerance')
      end
    end

    context 'when using percentage tolerance rules' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 3.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 98.00, # 2% difference
          transaction_date: 3.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:percentage_rule) do
        create(:reconciliation_rule,
          name: 'Percentage Tolerance',
          rule_type: 'percentage',
          priority: 3,
          active: true,
          default_tolerance_value: 5 # 5% tolerance
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: percentage_rule.id,
              name: 'Percentage Tolerance',
              rule_type: 'percentage',
              tolerance_value: 5,
              priority: 3,
              active: true
            }
          ])
      end

      it 'matches within percentage tolerance' do
        service.call
        reconciliation = service.reconciliation
        
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.matched_items.first.amount_difference).to eq(2.00)
        expect(reconciliation.matched_items.first.match_rule_applied).to eq('Percentage Tolerance')
      end
    end

    context 'when there are unmatched sales' do
      let!(:sale_without_transaction) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 200.00,
          sale_date: 2.days.ago,
          status: 'completed'
        )
      end

      let!(:unrelated_transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 300.00,
          transaction_date: 2.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: 1,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            }
          ])
      end

      it 'creates unmatched items for both sale and transaction' do
        service.call
        reconciliation = service.reconciliation
        
        expect(reconciliation.unmatched_items.count).to eq(2)
        expect(reconciliation.status).to eq('with_errors')
      end

      it 'correctly identifies unmatched sales' do
        service.call
        
        unmatched_sale_item = service.reconciliation.unmatched_items
          .find { |item| item.source_type == 'Sale' }
        
        expect(unmatched_sale_item.source).to eq(sale_without_transaction)
        expect(unmatched_sale_item.target).to be_nil
        expect(unmatched_sale_item.notes).to include("No matching transaction found")
      end

      it 'correctly identifies unmatched transactions' do
        service.call
        
        unmatched_transaction_item = service.reconciliation.unmatched_items
          .find { |item| item.source_type == 'Transaction' }
        
        expect(unmatched_transaction_item.source).to eq(unrelated_transaction)
        expect(unmatched_transaction_item.target).to be_nil
      end
    end

    context 'when multiple rules apply with priorities' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 2.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 99.00,
          transaction_date: 2.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:exact_rule) do
        create(:reconciliation_rule,
          name: 'Exact Match',
          rule_type: 'exact',
          priority: 1,
          active: true,
          default_tolerance_value: 0  # Required for exact match
        )
      end

      let!(:amount_rule) do
        create(:reconciliation_rule,
          name: 'Amount Tolerance',
          rule_type: 'amount',
          priority: 2,
          active: true,
          default_tolerance_value: 2
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: exact_rule.id,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            },
            {
              id: amount_rule.id,
              name: 'Amount Tolerance',
              rule_type: 'amount',
              tolerance_value: 2,
              priority: 2,
              active: true
            }
          ])
      end

      it 'applies rules in priority order' do
        service.call
        reconciliation = service.reconciliation
        
        # Should match with amount tolerance rule (priority 2) since exact match fails
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.matched_items.first.match_rule_applied).to eq('Amount Tolerance')
      end
    end

    context 'when store has custom rule configurations' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 5.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 100.00,
          transaction_date: 2.days.ago, # 3 days difference
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:date_rule) do
        create(:reconciliation_rule,
          name: 'Date Tolerance',
          rule_type: 'date',
          priority: 1,
          active: true,
          default_tolerance_value: 1 # Default is 1 day
        )
      end

      let!(:store_rule) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: date_rule,
          tolerance_value: 5, # Store overrides to 5 days
          priority: 1,
          active: true
        )
      end

      it 'uses store-specific tolerance values' do
        service.call
        reconciliation = service.reconciliation
        
        # Should match because store has 5 days tolerance
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.matched_items.first.match_rule_applied).to eq('Date Tolerance')
      end
    end

    context 'when wallet balances are inconsistent' do
      let!(:wallet_with_issue) do
        create(:wallet,
          owner: customer,
          wallet_type: 'customer',
          balance: 1000.00
        )
      end

      before do
        # Mock inconsistent balance
        allow(wallet_with_issue).to receive(:balance_consistency_check).and_return({
          is_consistent: false,
          current_balance: 1000.00,
          expected_balance: 950.00,
          difference: 50.00
        })
        
        allow(store).to receive(:wallets).and_return([wallet_with_issue])
        
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([])
      end

      it 'creates disputed items for wallet discrepancies' do
        service.call
        reconciliation = service.reconciliation
        
        disputed_items = reconciliation.reconciliation_items.where(match_status: 'disputed')
        expect(disputed_items.count).to be >= 1
        
        wallet_item = disputed_items.find { |item| item.source_type == 'Wallet' }
        expect(wallet_item).to be_present
        expect(wallet_item.amount_difference).to eq(50.00)
      end
    end

    context 'when there are no transactions or sales' do
      it 'completes successfully with no items' do
        service.call
        
        expect(service.valid?).to be true
        expect(service.reconciliation.status).to eq('completed')
        expect(service.matched_count).to eq(0)
        expect(service.unmatched_count).to eq(0)
      end
    end

    context 'when an error occurs during reconciliation' do
      before do
        allow(service).to receive(:load_source_data).and_raise(StandardError, 'Database error')
      end

      it 'marks reconciliation as failed' do
        service.call
        
        expect(service.valid?).to be false
        expect(service.reconciliation&.status).to eq('failed')
        expect(service.errors[:message]).to include('Database error')
      end
    end

    context 'when matching multiple sales to transactions' do
      let!(:sales) do
        3.times.map do |i|
          create(:sale,
            store: store,
            customer: customer,
            total_amount: 100.00 + (i * 10),
            sale_date: (3 - i).days.ago,
            status: 'completed'
          )
        end
      end

      let!(:transactions) do
        3.times.map do |i|
          create(:transaction,
            store: store,
            customer: customer,
            wallet: customer_wallet,
            amount: 100.00 + (i * 10),
            transaction_date: (3 - i).days.ago,
            transaction_type: 'payment',
            status: 'completed'
          )
        end
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: 1,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            }
          ])
      end

      it 'matches each sale to its corresponding transaction' do
        service.call
        reconciliation = service.reconciliation
        
        expect(reconciliation.matched_items.count).to eq(3)
        expect(reconciliation.unmatched_items.count).to eq(0)
        
        # Verify each sale is matched to the correct transaction
        sales.each_with_index do |sale, i|
          matched_item = reconciliation.matched_items.find { |item| item.source == sale }
          expect(matched_item.target).to eq(transactions[i])
        end
      end
    end

    context 'when transaction is already matched' do
      let!(:sale1) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 3.days.ago,
          status: 'completed'
        )
      end

      let!(:sale2) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 3.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 100.00,
          transaction_date: 3.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: 1,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            }
          ])
      end

      it 'does not match the same transaction twice' do
        service.call
        reconciliation = service.reconciliation
        
        # One sale should be matched, one should be unmatched
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.unmatched_items.count).to eq(1)
        
        unmatched_sale_item = reconciliation.unmatched_items.find { |item| item.source_type == 'Sale' }
        expect([sale1, sale2]).to include(unmatched_sale_item.source)
      end
    end

    context 'with refund transactions' do
      # Create a payment first so refund validation passes
      let!(:payment_transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 100.00,
          transaction_date: 3.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      let!(:refund_transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 50.00,
          transaction_date: 2.days.ago,
          transaction_type: 'refund',
          status: 'completed'
        )
      end

      before do
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([])
      end

      it 'includes refund transactions in reconciliation' do
        service.call
        reconciliation = service.reconciliation
        
        # Both payment and refund should be unmatched since there's no corresponding sale
        unmatched_items = reconciliation.unmatched_items
        
        unmatched_refund = unmatched_items.find { |item| item.source == refund_transaction }
        unmatched_payment = unmatched_items.find { |item| item.source == payment_transaction }
        
        expect(unmatched_refund).to be_present
        expect(unmatched_payment).to be_present
      end
    end
  end

  describe 'bug verification' do
    context 'when find_matching_transaction returns early' do
      let!(:sale) do
        create(:sale,
          store: store,
          customer: customer,
          total_amount: 100.00,
          sale_date: 3.days.ago,
          status: 'completed'
        )
      end

      let!(:transaction) do
        create(:transaction,
          store: store,
          customer: customer,
          wallet: customer_wallet,
          amount: 100.00,
          transaction_date: 3.days.ago,
          transaction_type: 'payment',
          status: 'completed'
        )
      end

      it 'correctly processes all sales after bug fix' do
        # This test verifies that the bug in line 68 has been fixed
        # Previously, 'return' would stop processing after first match
        # Now 'next' allows all sales to be processed
        
        # Mock wallet verification to avoid disputed items in this test
        allow_any_instance_of(described_class)
          .to receive(:verify_wallet_transactions).and_return(nil)
        
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:call).and_return(true)
        allow_any_instance_of(StoreReconciliationRules::GetRulesService)
          .to receive(:rules).and_return([
            {
              id: 1,
              name: 'Exact Match',
              rule_type: 'exact',
              tolerance_value: 0,
              priority: 1,
              active: true
            }
          ])

        # Add a second sale that should also be processed
        sale2 = create(:sale,
          store: store,
          customer: customer,
          total_amount: 200.00,
          sale_date: 2.days.ago,
          status: 'completed'
        )

        service.call
        reconciliation = service.reconciliation

        # After the fix: All sales are processed
        # Expected: 1 matched (sale with transaction), 1 unmatched (sale2)
        # The transaction is matched to sale, so it's not unmatched
        
        total_items = reconciliation.reconciliation_items.count
        expect(total_items).to eq(2) # 1 matched + 1 unmatched item
        
        # Verify the matched item
        expect(reconciliation.matched_items.count).to eq(1)
        expect(reconciliation.matched_items.first.source).to eq(sale)
        expect(reconciliation.matched_items.first.target).to eq(transaction)
        
        # Verify unmatched items (only sale2 should be unmatched)
        expect(reconciliation.unmatched_items.count).to eq(1)
        unmatched_item = reconciliation.unmatched_items.first
        expect(unmatched_item.source).to eq(sale2)
      end
    end
  end
end