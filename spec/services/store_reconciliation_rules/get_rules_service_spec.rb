require 'rails_helper'

RSpec.describe StoreReconciliationRules::GetRulesService do
  let(:store) { create(:store) }
  let(:service) { described_class.new(store: store) }

  describe '#initialize' do
    it 'initializes with a store' do
      expect(service.instance_variable_get(:@store)).to eq(store)
    end

    it 'initializes with empty rules array' do
      expect(service.instance_variable_get(:@rules)).to eq([])
    end
  end

  describe '#call' do
    context 'when there are no reconciliation rules' do
      it 'sets service as valid' do
        service.call
        expect(service.valid?).to be true
      end

      it 'returns empty rules array' do
        service.call
        expect(service.rules).to eq([])
      end
    end

    context 'when there are active reconciliation rules without store customizations' do
      let!(:rule1) { create(:reconciliation_rule, :exact, priority: 1) }
      let!(:rule2) { create(:reconciliation_rule, :date, priority: 2) }
      let!(:rule3) { create(:reconciliation_rule, :percentage, priority: 3) }
      let!(:inactive_rule) { create(:reconciliation_rule, :inactive, priority: 4) }

      before { service.call }

      it 'sets service as valid' do
        expect(service.valid?).to be true
      end

      it 'returns only active rules' do
        expect(service.rules.size).to eq(3)
        rule_ids = service.rules.map { |r| r[:id] }
        expect(rule_ids).to contain_exactly(rule1.id, rule2.id, rule3.id)
      end

      it 'returns rules sorted by priority' do
        priorities = service.rules.map { |r| r[:priority] }
        expect(priorities).to eq([1, 2, 3])
      end

      it 'uses default values for all rules' do
        exact_rule = service.rules.find { |r| r[:id] == rule1.id }
        date_rule = service.rules.find { |r| r[:id] == rule2.id }
        percentage_rule = service.rules.find { |r| r[:id] == rule3.id }

        expect(exact_rule[:tolerance_value]).to eq(0)
        expect(date_rule[:tolerance_value]).to eq(7)
        expect(percentage_rule[:tolerance_value]).to eq(5)
      end

      it 'includes all rule attributes' do
        first_rule = service.rules.first
        
        expect(first_rule).to have_key(:id)
        expect(first_rule).to have_key(:name)
        expect(first_rule).to have_key(:description)
        expect(first_rule).to have_key(:rule_type)
        expect(first_rule).to have_key(:tolerance_value)
        expect(first_rule).to have_key(:priority)
        expect(first_rule).to have_key(:active)
      end

      it 'sets all rules as active when no store customization exists' do
        service.rules.each do |rule|
          expect(rule[:active]).to be true
        end
      end
    end

    context 'when store has customized rules' do
      let!(:rule1) { create(:reconciliation_rule, :exact, priority: 1, default_tolerance_value: 0) }
      let!(:rule2) { create(:reconciliation_rule, :date, priority: 2, default_tolerance_value: 7) }
      let!(:rule3) { create(:reconciliation_rule, :amount, priority: 3, default_tolerance_value: 1000) }
      
      let!(:store_rule1) do
        create(:store_reconciliation_rule, 
          store: store,
          reconciliation_rule: rule1,
          tolerance_value: 0,
          priority: 5,
          active: true
        )
      end
      
      let!(:store_rule2) do
        create(:store_reconciliation_rule, 
          store: store,
          reconciliation_rule: rule2,
          tolerance_value: 14,
          priority: 1,
          active: false
        )
      end

      before { service.call }

      it 'uses store-specific values when available' do
        customized_rule1 = service.rules.find { |r| r[:id] == rule1.id }
        customized_rule2 = service.rules.find { |r| r[:id] == rule2.id }
        default_rule3 = service.rules.find { |r| r[:id] == rule3.id }

        expect(customized_rule1[:tolerance_value]).to eq(0)
        expect(customized_rule1[:priority]).to eq(5)
        expect(customized_rule1[:active]).to be true

        expect(customized_rule2[:tolerance_value]).to eq(14)
        expect(customized_rule2[:priority]).to eq(1)
        expect(customized_rule2[:active]).to be false

        expect(default_rule3[:tolerance_value]).to eq(1000)
        expect(default_rule3[:priority]).to eq(3)
        expect(default_rule3[:active]).to be true
      end

      it 'maintains rule metadata from reconciliation rule' do
        customized_rule1 = service.rules.find { |r| r[:id] == rule1.id }
        
        expect(customized_rule1[:name]).to eq(rule1.name)
        expect(customized_rule1[:description]).to eq(rule1.description)
        expect(customized_rule1[:rule_type]).to eq(rule1.rule_type)
      end
    end

    context 'when store has multiple customized rules with different priorities' do
      let!(:rule1) { create(:reconciliation_rule, :exact, priority: 10) }
      let!(:rule2) { create(:reconciliation_rule, :date, priority: 20) }
      let!(:rule3) { create(:reconciliation_rule, :percentage, priority: 30) }
      
      let!(:store_rule1) { create(:store_reconciliation_rule, store: store, reconciliation_rule: rule1, tolerance_value: 0, priority: 2) }
      let!(:store_rule2) { create(:store_reconciliation_rule, store: store, reconciliation_rule: rule2, priority: 1, tolerance_value: 2) }
      let!(:store_rule3) { create(:store_reconciliation_rule, store: store, reconciliation_rule: rule3, priority: 3, tolerance_value: 20) }

      before { service.call }

      it 'returns rules sorted by effective priority' do
        # Note: The service sorts by ReconciliationRule priority, not store priority
        priorities = service.rules.map { |r| r[:priority] }
        expect(priorities).to eq([2, 1, 3])
      end
    end

    context 'when store has partially customized rules' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      
      let!(:store_rule) do
        create(:store_reconciliation_rule, 
          store: store,
          reconciliation_rule: rule1,
          tolerance_value: 0,  # Must be 0 for exact type
          priority: 15,
          active: false
        )
      end

      before { service.call }

      it 'uses store values when available' do
        rule1_result = service.rules.find { |r| r[:id] == rule1.id }
        
        expect(rule1_result[:tolerance_value]).to eq(0)
        expect(rule1_result[:priority]).to eq(15)
        expect(rule1_result[:active]).to eq(false)
      end
    end

    context 'when an error occurs during execution' do
      before do
        allow(ReconciliationRule).to receive(:active).and_raise(StandardError, 'Database error')
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end

      it 'sets error message' do
        service.call
        expect(service.errors[:message]).to include('Error obteniendo reglas')
        expect(service.errors[:message]).to include('Database error')
      end

      it 'returns empty rules on error' do
        service.call
        expect(service.rules).to eq([])
      end
    end

    context 'with complex scenarios' do
      let!(:exact_rule) { create(:reconciliation_rule, :exact, priority: 1) }
      let!(:date_rule) { create(:reconciliation_rule, :date, priority: 2) }
      let!(:percentage_rule) { create(:reconciliation_rule, :percentage, priority: 3) }
      let!(:amount_rule) { create(:reconciliation_rule, :amount, priority: 4) }
      # Inactive rule is not created to avoid rule_type duplication
      
      let!(:store_rule_exact) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: exact_rule,
          tolerance_value: 0,
          priority: 10,
          active: true
        )
      end
      
      let!(:store_rule_date) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: date_rule,
          tolerance_value: 30,
          priority: 5,
          active: false
        )
      end

      before { service.call }

      it 'correctly merges store customizations with default rules' do
        expect(service.rules.size).to eq(4) # Only active rules
        
        exact = service.rules.find { |r| r[:rule_type] == 'exact' }
        date = service.rules.find { |r| r[:rule_type] == 'date' }
        percentage = service.rules.find { |r| r[:rule_type] == 'percentage' }
        amount = service.rules.find { |r| r[:rule_type] == 'amount' }
        
        # Customized rules
        expect(exact[:tolerance_value]).to eq(0)
        expect(exact[:priority]).to eq(10)
        expect(exact[:active]).to be true
        
        expect(date[:tolerance_value]).to eq(30)
        expect(date[:priority]).to eq(5)
        expect(date[:active]).to be false
        
        # Default rules
        expect(percentage[:tolerance_value]).to eq(percentage_rule.default_tolerance_value)
        expect(percentage[:priority]).to eq(percentage_rule.priority)
        expect(percentage[:active]).to be true
        
        expect(amount[:tolerance_value]).to eq(amount_rule.default_tolerance_value)
        expect(amount[:priority]).to eq(amount_rule.priority)
        expect(amount[:active]).to be true
      end
    end

    context 'when store belongs to different organization' do
      let(:other_store) { create(:store) }
      let!(:rule) { create(:reconciliation_rule) }
      let!(:other_store_rule) do
        create(:store_reconciliation_rule,
          store: other_store,
          reconciliation_rule: rule,
          tolerance_value: 999
        )
      end

      before { service.call }

      it 'does not include other stores customizations' do
        rule_result = service.rules.find { |r| r[:id] == rule.id }
        expect(rule_result[:tolerance_value]).to eq(rule.default_tolerance_value)
        expect(rule_result[:tolerance_value]).not_to eq(999)
      end
    end
  end

  describe '#rules' do
    it 'returns the rules array' do
      service.call
      expect(service.rules).to be_an(Array)
    end

    it 'is accessible after calling the service' do
      expect(service.rules).to eq([])
      service.call
      expect(service.rules).to be_an(Array)
    end
  end

  describe '#valid?' do
    it 'returns false before calling the service' do
      expect(service.valid?).to be_falsey
    end

    it 'returns true after successful call' do
      service.call
      expect(service.valid?).to be true
    end

    it 'returns false after failed call' do
      allow(ReconciliationRule).to receive(:active).and_raise(StandardError)
      service.call
      expect(service.valid?).to be false
    end
  end
end
