require 'rails_helper'

RSpec.describe StoreReconciliationRules::UpdateRulesService do
  let(:store) { create(:store) }
  let(:rules_params) { [] }
  let(:service) { described_class.new(store: store, rules_params: rules_params) }

  describe '#initialize' do
    it 'initializes with a store and rules params' do
      expect(service.instance_variable_get(:@store)).to eq(store)
      expect(service.instance_variable_get(:@rules_params)).to eq(rules_params)
    end

    it 'initializes with empty updated_rules array' do
      expect(service.instance_variable_get(:@updated_rules)).to eq([])
    end

    it 'initializes with empty rules_errors array' do
      expect(service.instance_variable_get(:@rules_errors)).to eq([])
    end
  end

  describe '#call' do
    context 'when no rules params are provided' do
      let(:rules_params) { [] }

      it 'sets service as valid' do
        service.call
        expect(service.valid?).to be true
      end

      it 'returns empty updated_rules array' do
        service.call
        expect(service.updated_rules).to eq([])
      end
    end

    context 'when creating new store rules' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      
      let(:rules_params) do
        [
          {
            rule_id: rule1.id,
            tolerance_value: 0,
            priority: 5,
            active: true
          },
          {
            rule_id: rule2.id,
            tolerance_value: 14,
            priority: 10,
            active: false
          }
        ]
      end

      it 'creates new store reconciliation rules' do
        expect {
          service.call
        }.to change { StoreReconciliationRule.count }.by(2)
      end

      it 'sets service as valid' do
        service.call
        expect(service.valid?).to be true
      end

      it 'returns created rules' do
        service.call
        expect(service.updated_rules.size).to eq(2)
        expect(service.updated_rules).to all(be_a(StoreReconciliationRule))
      end

      it 'creates rules with correct attributes' do
        service.call
        
        rule1_store = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule1
        )
        
        expect(rule1_store.tolerance_value).to eq(0)
        expect(rule1_store.priority).to eq(5)
        expect(rule1_store.active).to be true
        
        rule2_store = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule2
        )
        
        expect(rule2_store.tolerance_value).to eq(14)
        expect(rule2_store.priority).to eq(10)
        expect(rule2_store.active).to be false
      end
    end

    context 'when updating existing store rules' do
      let!(:rule) { create(:reconciliation_rule, :percentage) }
      let!(:existing_store_rule) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: rule,
          tolerance_value: 5,
          priority: 15,
          active: true
        )
      end
      
      let(:rules_params) do
        [
          {
            rule_id: rule.id,
            tolerance_value: 10,
            priority: 20,
            active: false
          }
        ]
      end

      it 'does not create new rules' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end

      it 'updates existing rule' do
        service.call
        existing_store_rule.reload
        
        expect(existing_store_rule.tolerance_value).to eq(10)
        expect(existing_store_rule.priority).to eq(20)
        expect(existing_store_rule.active).to be false
      end

      it 'sets service as valid' do
        service.call
        expect(service.valid?).to be true
      end

      it 'returns updated rules' do
        service.call
        expect(service.updated_rules.size).to eq(1)
        expect(service.updated_rules.first.id).to eq(existing_store_rule.id)
      end
    end

    context 'when mixing create and update operations' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      let!(:existing_store_rule) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: rule1,
          tolerance_value: 0,
          priority: 5,
          active: true
        )
      end
      
      let(:rules_params) do
        [
          {
            rule_id: rule1.id,
            tolerance_value: 0,  # Must be 0 for exact type
            priority: 10,
            active: false
          },
          {
            rule_id: rule2.id,
            tolerance_value: 30,  # Valid for date type (max 31)
            priority: 15,
            active: true
          }
        ]
      end

      it 'creates one new rule and updates one existing rule' do
        expect {
          service.call
        }.to change { StoreReconciliationRule.count }.by(1)
      end

      it 'updates existing rule correctly' do
        service.call
        existing_store_rule.reload
        
        expect(existing_store_rule.tolerance_value).to eq(0)
        expect(existing_store_rule.priority).to eq(10)
        expect(existing_store_rule.active).to be false
      end

      it 'creates new rule correctly' do
        service.call
        new_rule = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule2
        )
        
        expect(new_rule.tolerance_value).to eq(30)
        expect(new_rule.priority).to eq(15)
        expect(new_rule.active).to be true
      end

      it 'returns all processed rules' do
        service.call
        expect(service.updated_rules.size).to eq(2)
      end
    end

    context 'when rule_id does not exist' do
      let(:rules_params) do
        [
          {
            rule_id: 999999,
            tolerance_value: 100,
            priority: 10,
            active: true
          }
        ]
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end

      it 'sets error message' do
        service.call
        expect(service.errors[:message]).to include('Regla no encontrada')
        expect(service.errors[:message]).to include('999999')
      end

      it 'does not create any rules' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end

      it 'returns empty updated_rules' do
        service.call
        expect(service.updated_rules).to eq([])
      end
    end

    context 'when validation fails' do
      let!(:rule) { create(:reconciliation_rule, :percentage) }
      let(:rules_params) do
        [
          {
            rule_id: rule.id,
            tolerance_value: -10, # Invalid negative value
            priority: 0, # Invalid priority (must be >= 1)
            active: true
          }
        ]
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end

      it 'sets error message with validation errors' do
        service.call
        expect(service.errors[:message]).to include(rule.name)
      end

      it 'does not create any rules' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end

      it 'rolls back transaction' do
        service.call
        expect(StoreReconciliationRule.where(store: store)).to be_empty
      end
    end

    context 'when multiple rules have errors' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      
      let(:rules_params) do
        [
          {
            rule_id: 999999, # Non-existent
            tolerance_value: 100,
            priority: 10,
            active: true
          },
          {
            rule_id: rule2.id,
            tolerance_value: -5, # Invalid
            priority: 0, # Invalid
            active: false
          }
        ]
      end

      it 'collects all error messages' do
        service.call
        error_message = service.errors[:message]
        
        expect(error_message).to include('Regla no encontrada')
        expect(error_message).to include('999999')
      end

      it 'does not create any rules when any fails' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end
    end

    context 'when handling string parameters' do
      let!(:rule) { create(:reconciliation_rule, :amount) }
      let(:rules_params) do
        [
          {
            rule_id: rule.id.to_s,
            tolerance_value: '1000.50',
            priority: '25',
            active: 'true'
          }
        ]
      end

      it 'correctly converts string parameters' do
        service.call
        store_rule = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule
        )
        
        expect(store_rule.tolerance_value).to eq(1000.50)
        expect(store_rule.priority).to eq(25)
        expect(store_rule.active).to be true
      end

      it 'sets service as valid' do
        service.call
        expect(service.valid?).to be true
      end
    end

    context 'when duplicate priority for same store' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      let!(:existing_store_rule) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: rule1,
          tolerance_value: 0,
          priority: 10,
          active: true
        )
      end
      
      let(:rules_params) do
        [
          {
            rule_id: rule2.id,
            tolerance_value: 5,
            priority: 10,  # Same priority as existing rule
            active: true
          }
        ]
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end

      it 'sets error message about duplicate priority' do
        service.call
        expect(service.errors[:message]).to include('ya existe otra regla con esta prioridad')
      end

      it 'does not create the duplicate priority rule' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end
    end

    context 'when tolerance_value invalid for rule type' do
      context 'exact type with non-zero tolerance' do
        let!(:rule) { create(:reconciliation_rule, :exact) }
        let(:rules_params) do
          [
            {
              rule_id: rule.id,
              tolerance_value: 5,  # Invalid for exact type (must be 0)
              priority: 10,
              active: true
            }
          ]
        end

        it 'sets service as invalid' do
          service.call
          expect(service.valid?).to be false
        end

        it 'sets error message about tolerance value' do
          service.call
          expect(service.errors[:message]).to include('debe ser 0 para match exacto')
        end
      end

      context 'date type with tolerance > 31' do
        let!(:rule) { create(:reconciliation_rule, :date) }
        let(:rules_params) do
          [
            {
              rule_id: rule.id,
              tolerance_value: 32,  # Invalid for date type (max 31)
              priority: 10,
              active: true
            }
          ]
        end

        it 'sets service as invalid' do
          service.call
          expect(service.valid?).to be false
        end

        it 'sets error message about tolerance value' do
          service.call
          expect(service.errors[:message]).to include('debe ser entre 0 y 31 días')
        end
      end

      context 'percentage type with tolerance > 100' do
        let!(:rule) { create(:reconciliation_rule, :percentage) }
        let(:rules_params) do
          [
            {
              rule_id: rule.id,
              tolerance_value: 101,  # Invalid for percentage type (max 100)
              priority: 10,
              active: true
            }
          ]
        end

        it 'sets service as invalid' do
          service.call
          expect(service.valid?).to be false
        end

        it 'sets error message about tolerance value' do
          service.call
          expect(service.errors[:message]).to include('debe ser entre 0 y 100%')
        end
      end
    end

    context 'when a database error occurs' do
      let!(:rule) { create(:reconciliation_rule, :exact) }
      let(:rules_params) do
        [
          {
            rule_id: rule.id,
            tolerance_value: 0,
            priority: 10,
            active: true
          }
        ]
      end

      before do
        allow_any_instance_of(StoreReconciliationRule).to receive(:save).and_raise(StandardError, 'Database error')
      end

      it 'sets service as invalid' do
        service.call
        expect(service.valid?).to be false
      end

      it 'sets error message' do
        service.call
        expect(service.errors[:message]).to include('Error actualizando reglas')
        expect(service.errors[:message]).to include('Database error')
      end

      it 'does not create any rules' do
        expect {
          service.call
        }.not_to change { StoreReconciliationRule.count }
      end
    end

    context 'with complex scenarios' do
      let!(:rule1) { create(:reconciliation_rule, :exact) }
      let!(:rule2) { create(:reconciliation_rule, :date) }
      let!(:rule3) { create(:reconciliation_rule, :percentage) }
      let!(:rule4) { create(:reconciliation_rule, :amount) }
      
      let!(:existing_rule1) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: rule1,
          tolerance_value: 0,
          priority: 1,
          active: true
        )
      end
      
      let!(:existing_rule3) do
        create(:store_reconciliation_rule,
          store: store,
          reconciliation_rule: rule3,
          tolerance_value: 5,
          priority: 20,
          active: true
        )
      end
      
      let(:rules_params) do
        [
          # Update existing rule1
          {
            rule_id: rule1.id,
            tolerance_value: 0,
            priority: 5,
            active: false
          },
          # Create new rule2
          {
            rule_id: rule2.id,
            tolerance_value: 15,
            priority: 10,
            active: true
          },
          # Update existing rule3
          {
            rule_id: rule3.id,
            tolerance_value: 10,
            priority: 15,
            active: false
          },
          # Create new rule4
          {
            rule_id: rule4.id,
            tolerance_value: 5000,
            priority: 25,
            active: true
          }
        ]
      end

      it 'processes all rules correctly' do
        expect {
          service.call
        }.to change { StoreReconciliationRule.count }.by(2)
        
        expect(service.valid?).to be true
        expect(service.updated_rules.size).to eq(4)
      end

      it 'updates and creates rules with correct values' do
        service.call
        
        # Check updated rules
        existing_rule1.reload
        expect(existing_rule1.priority).to eq(5)
        expect(existing_rule1.active).to be false
        
        existing_rule3.reload
        expect(existing_rule3.tolerance_value).to eq(10)
        expect(existing_rule3.priority).to eq(15)
        expect(existing_rule3.active).to be false
        
        # Check new rules
        new_rule2 = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule2
        )
        expect(new_rule2.tolerance_value).to eq(15)
        expect(new_rule2.priority).to eq(10)
        expect(new_rule2.active).to be true
        
        new_rule4 = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule4
        )
        expect(new_rule4.tolerance_value).to eq(5000)
        expect(new_rule4.priority).to eq(25)
        expect(new_rule4.active).to be true
      end
    end

    context 'when store already has a rule for the same reconciliation_rule' do
      let!(:rule) { create(:reconciliation_rule, :exact) }
      let!(:other_store) { create(:store) }
      let!(:other_store_rule) do
        create(:store_reconciliation_rule,
          store: other_store,
          reconciliation_rule: rule,
          tolerance_value: 0,
          priority: 99,
          active: false
        )
      end
      
      let(:rules_params) do
        [
          {
            rule_id: rule.id,
            tolerance_value: 0,
            priority: 10,
            active: true
          }
        ]
      end

      it 'does not affect other stores rules' do
        service.call
        other_store_rule.reload
        
        expect(other_store_rule.tolerance_value).to eq(0)
        expect(other_store_rule.priority).to eq(99)
        expect(other_store_rule.active).to be false
      end

      it 'creates rule only for the current store' do
        service.call
        
        store_rule = StoreReconciliationRule.find_by(
          store: store,
          reconciliation_rule: rule
        )
        
        expect(store_rule).to be_present
        expect(store_rule.tolerance_value).to eq(0)
        expect(store_rule.priority).to eq(10)
        expect(store_rule.active).to be true
      end
    end
  end

  describe '#updated_rules' do
    it 'returns the updated_rules array' do
      service.call
      expect(service.updated_rules).to be_an(Array)
    end

    it 'is accessible after calling the service' do
      expect(service.updated_rules).to eq([])
      service.call
      expect(service.updated_rules).to be_an(Array)
    end
  end

  describe '#valid?' do
    it 'returns false before calling the service' do
      expect(service.valid?).to be_falsey
    end

    context 'with valid params' do
      let!(:rule) { create(:reconciliation_rule, :exact) }
      let(:rules_params) do
        [{
          rule_id: rule.id,
          tolerance_value: 0,
          priority: 10,
          active: true
        }]
      end

      it 'returns true after successful call' do
        service.call
        expect(service.valid?).to be true
      end
    end

    context 'with invalid params' do
      let(:rules_params) do
        [{
          rule_id: 999999,
          tolerance_value: 100,
          priority: 10,
          active: true
        }]
      end

      it 'returns false after failed call' do
        service.call
        expect(service.valid?).to be false
      end
    end
  end
end