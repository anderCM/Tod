# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe ReconciliationServices::CsvReconciliationService, type: :service do
  let(:store1) { create(:store, name: 'Tienda Norte') }
  let(:store2) { create(:store, name: 'Tienda Sur') }
  let(:start_date) { Date.parse('2025-08-15') }
  let(:end_date) { Date.parse('2025-08-17') }

  let(:csv_content) do
    CSV.generate(headers: true) do |csv|
      csv << ['fecha_transferencia', 'tienda_id', 'tienda_nombre', 'tienda_tax_id', 
              'total_ventas_dia', 'cantidad_transacciones', 'monto_transferencia', 
              'referencia_transferencia', 'estado_transferencia', 'observaciones']
      csv << ['2025-08-15', store1.id, 'Tienda Norte', '12345678-9', 
              '1000.00', '5', '1000.00', 'REF-001', 'completed', 'Depósito diario']
      csv << ['2025-08-16', store1.id, 'Tienda Norte', '12345678-9', 
              '1500.00', '7', '1500.00', 'REF-002', 'completed', 'Depósito diario']
      csv << ['2025-08-15', store2.id, 'Tienda Sur', '98765432-1', 
              '800.00', '4', '800.00', 'REF-003', 'completed', 'Depósito diario']
    end
  end

  let(:service) do
    described_class.new(
      start_date: start_date,
      end_date: end_date,
      csv_file: csv_content,
      initiated_by: 'admin'
    )
  end

  describe '#call' do
    context 'with perfect matches' do
      before do
        # Create matching transactions for store1 on 2025-08-15
        5.times do |i|
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store1,
            customer: customer,
            wallet: wallet,
            amount: 200.00,
            transaction_date: Date.parse('2025-08-15'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end

        # Create matching transactions for store1 on 2025-08-16
        # First 6 transactions with 214.29, last one with 214.26 to sum exactly 1500.00
        6.times do |i|
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store1,
            customer: customer,
            wallet: wallet,
            amount: 214.29,
            transaction_date: Date.parse('2025-08-16'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end
        # Last transaction to complete exactly 1500.00
        customer = create(:customer)
        wallet = create(:wallet, owner: customer, wallet_type: 'customer')
        create(:transaction,
          store: store1,
          customer: customer,
          wallet: wallet,
          amount: 214.26, # 1500 - (214.29 * 6) = 214.26
          transaction_date: Date.parse('2025-08-16'),
          transaction_type: 'payment',
          status: 'completed'
        )

        # Create matching transactions for store2 on 2025-08-15
        4.times do |i|
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store2,
            customer: customer,
            wallet: wallet,
            amount: 200.00,
            transaction_date: Date.parse('2025-08-15'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end
      end

      it 'creates reconciliations for each store' do
        expect { service.call }.to change { Reconciliation.count }.by(2)
        expect(service.valid?).to be true
      end

      it 'matches all CSV rows correctly' do
        service.call
        
        expect(service.matched_count).to eq(3) # 3 CSV rows matched
        expect(service.unmatched_count).to eq(0)
      end

      it 'creates a reconciliation file' do
        expect { service.call }.to change { ReconciliationFile.count }.by(1)
        
        file = ReconciliationFile.last
        expect(file.status).to eq('completed')
        expect(file.file_type).to eq('csv')
      end

      it 'calculates totals correctly' do
        service.call
        
        expect(service.total_amount_matched).to eq(3300.00) # 1000 + 1500 + 800
        expect(service.total_amount_unmatched).to eq(0)
      end

      it 'provides summary by store' do
        service.call
        summary = service.summary_by_store
        
        expect(summary.length).to eq(2)
        
        store1_summary = summary.find { |s| s[:store_id] == store1.id }
        expect(store1_summary[:matched_count]).to eq(2)
        expect(store1_summary[:unmatched_count]).to eq(0)
        expect(store1_summary[:store_name]).to eq('Tienda Norte')
        
        store2_summary = summary.find { |s| s[:store_id] == store2.id }
        expect(store2_summary[:matched_count]).to eq(1)
        expect(store2_summary[:unmatched_count]).to eq(0)
        expect(store2_summary[:store_name]).to eq('Tienda Sur')
      end
    end

    context 'with mismatched amount or count' do
      before do
        # Create transactions with different amounts for store1
        3.times do
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store1,
            customer: customer,
            wallet: wallet,
            amount: 200.00,
            transaction_date: Date.parse('2025-08-15'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end
        # Total: 600 (vs 1000 expected) and count is wrong (3 vs 5)
      end

      it 'marks items as unmatched when amount or count does not match' do
        service.call
        
        reconciliation = Reconciliation.find_by(store: store1)
        
        # Should be unmatched since neither amount nor count matches
        unmatched_items = reconciliation.reconciliation_items.where(match_status: 'unmatched')
        expect(unmatched_items.count).to be > 0
        
        # No matched items since nothing matches perfectly
        matched_items = reconciliation.reconciliation_items.where(match_status: 'matched')
        expect(matched_items.count).to eq(0)
      end
    end

    context 'with unmatched rows' do
      # No transactions created, all CSV rows should be unmatched
      
      it 'marks all rows as unmatched when no transactions exist' do
        service.call
        
        expect(service.matched_count).to eq(0)
        expect(service.unmatched_count).to eq(3) # All 3 CSV rows
      end

      it 'creates reconciliation items with proper notes' do
        service.call
        
        items = ReconciliationItem.all
        expect(items.count).to eq(3)
        
        items.each do |item|
          expect(item.match_status).to eq('unmatched')
          notes = JSON.parse(item.notes)
          expect(notes).to have_key('csv_reference')
          expect(notes).to have_key('csv_amount')
          expect(notes).to have_key('actual_amount')
          expect(notes['actual_amount']).to eq(0)
        end
      end
    end

    context 'with sales data' do
      before do
        # Create sales for store1
        3.times do
          create(:sale,
            store: store1,
            customer: create(:customer),
            total_amount: 333.33,
            sale_date: Date.parse('2025-08-15'),
            status: 'completed'
          )
        end
      end

      it 'includes sales information in reconciliation notes' do
        service.call
        
        item = ReconciliationItem.first
        notes = JSON.parse(item.notes)
        
        expect(notes['sales_total'].to_f).to be >= 999.99
        expect(notes['sales_count']).to eq(3)
      end
    end

    context 'with CSV file upload' do
      let(:temp_file) do
        file = Tempfile.new(['test', '.csv'])
        file.write(csv_content)
        file.rewind
        file
      end

      let(:uploaded_file) do
        ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'bank_deposits.csv',
          type: 'text/csv'
        )
      end

      let(:service_with_file) do
        described_class.new(
          start_date: start_date,
          end_date: end_date,
          csv_file: uploaded_file,
          initiated_by: 'admin'
        )
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'handles uploaded file correctly' do
        service_with_file.call
        
        expect(service_with_file.valid?).to be true
        file = ReconciliationFile.last
        expect(file.file_name).to eq('bank_deposits.csv')
      end
    end

    context 'with date filtering' do
      let(:csv_with_extra_dates) do
        CSV.generate(headers: true) do |csv|
          csv << ['fecha_transferencia', 'tienda_id', 'tienda_nombre', 'tienda_tax_id', 
                  'total_ventas_dia', 'cantidad_transacciones', 'monto_transferencia', 
                  'referencia_transferencia', 'estado_transferencia', 'observaciones']
          # Within range
          csv << ['2025-08-16', store1.id, 'Tienda Norte', '12345678-9', 
                  '1000.00', '5', '1000.00', 'REF-001', 'completed', 'Depósito']
          # Outside range (before)
          csv << ['2025-08-10', store1.id, 'Tienda Norte', '12345678-9', 
                  '500.00', '3', '500.00', 'REF-002', 'completed', 'Depósito']
          # Outside range (after)
          csv << ['2025-08-20', store1.id, 'Tienda Norte', '12345678-9', 
                  '700.00', '4', '700.00', 'REF-003', 'completed', 'Depósito']
        end
      end

      let(:service_with_dates) do
        described_class.new(
          start_date: start_date,
          end_date: end_date,
          csv_file: csv_with_extra_dates,
          initiated_by: 'admin'
        )
      end

      it 'only processes rows within the date range' do
        service_with_dates.call
        
        expect(service_with_dates.processed_rows).to eq(1)
        items = ReconciliationItem.all
        expect(items.count).to eq(1)
        
        notes = JSON.parse(items.first.notes)
        expect(notes['csv_date']).to eq('2025-08-16')
      end
    end

    context 'with unknown store IDs' do
      let(:csv_with_unknown_store) do
        CSV.generate(headers: true) do |csv|
          csv << ['fecha_transferencia', 'tienda_id', 'tienda_nombre', 'tienda_tax_id', 
                  'total_ventas_dia', 'cantidad_transacciones', 'monto_transferencia', 
                  'referencia_transferencia', 'estado_transferencia', 'observaciones']
          csv << ['2025-08-15', 99999, 'Unknown Store', '00000000-0', 
                  '1000.00', '5', '1000.00', 'REF-001', 'completed', 'Unknown']
          csv << ['2025-08-15', store1.id, 'Tienda Norte', '12345678-9', 
                  '500.00', '3', '500.00', 'REF-002', 'completed', 'Known']
        end
      end

      let(:service_unknown) do
        described_class.new(
          start_date: start_date,
          end_date: end_date,
          csv_file: csv_with_unknown_store,
          initiated_by: 'admin'
        )
      end

      it 'skips unknown stores and processes known ones' do
        expect(Rails.logger).to receive(:warn).with(/unknown store IDs: 99999/)
        
        service_unknown.call
        
        expect(service_unknown.valid?).to be true
        expect(Reconciliation.count).to eq(1)
        expect(Reconciliation.first.store).to eq(store1)
      end
    end

    context 'error handling' do
      context 'with malformed CSV' do
        let(:malformed_csv) { "This is not, a valid CSV\nWith broken\"quotes" }
        
        let(:service_malformed) do
          described_class.new(
            start_date: start_date,
            end_date: end_date,
            csv_file: malformed_csv,
            initiated_by: 'admin'
          )
        end

        it 'handles CSV parsing errors gracefully' do
          service_malformed.call
          
          expect(service_malformed.valid?).to be false
          expect(service_malformed.errors[:message]).to match(/Invalid CSV format|Error parsing CSV/)
        end
      end

      context 'with invalid date format' do
        let(:csv_invalid_date) do
          CSV.generate(headers: true) do |csv|
            csv << ['fecha_transferencia', 'tienda_id', 'tienda_nombre', 'tienda_tax_id', 
                    'total_ventas_dia', 'cantidad_transacciones', 'monto_transferencia', 
                    'referencia_transferencia', 'estado_transferencia', 'observaciones']
            csv << ['invalid-date', store1.id, 'Tienda Norte', '12345678-9', 
                    '1000.00', '5', '1000.00', 'REF-001', 'completed', 'Test']
          end
        end

        let(:service_invalid_date) do
          described_class.new(
            start_date: start_date,
            end_date: end_date,
            csv_file: csv_invalid_date,
            initiated_by: 'admin'
          )
        end

        it 'handles date parsing errors' do
          service_invalid_date.call
          
          expect(service_invalid_date.valid?).to be false
          expect(service_invalid_date.errors[:message]).to include('Error parsing CSV')
        end
      end

      context 'when transaction fails' do
        before do
          allow(Reconciliation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Reconciliation.new))
        end

        it 'rolls back all changes' do
          expect { service.call }.not_to change { Reconciliation.count }
          expect(service.valid?).to be false
        end
      end
    end

    context 'with multiple stores and complex scenarios' do
      let(:complex_csv) do
        CSV.generate(headers: true) do |csv|
          csv << ['fecha_transferencia', 'tienda_id', 'tienda_nombre', 'tienda_tax_id', 
                  'total_ventas_dia', 'cantidad_transacciones', 'monto_transferencia', 
                  'referencia_transferencia', 'estado_transferencia', 'observaciones']
          # Store 1 - multiple days
          csv << ['2025-08-15', store1.id, 'Tienda Norte', '12345678-9', 
                  '1000.00', '5', '1000.00', 'REF-001', 'completed', 'Day 1']
          csv << ['2025-08-16', store1.id, 'Tienda Norte', '12345678-9', 
                  '1500.00', '7', '1500.00', 'REF-002', 'completed', 'Day 2']
          csv << ['2025-08-17', store1.id, 'Tienda Norte', '12345678-9', 
                  '800.00', '4', '800.00', 'REF-003', 'completed', 'Day 3']
          
          # Store 2 - multiple days
          csv << ['2025-08-15', store2.id, 'Tienda Sur', '98765432-1', 
                  '2000.00', '10', '2000.00', 'REF-004', 'completed', 'Day 1']
          csv << ['2025-08-16', store2.id, 'Tienda Sur', '98765432-1', 
                  '2500.00', '12', '2500.00', 'REF-005', 'completed', 'Day 2']
        end
      end

      let(:service_complex) do
        described_class.new(
          start_date: start_date,
          end_date: end_date,
          csv_file: complex_csv,
          initiated_by: 'admin'
        )
      end

      before do
        # Create some matching transactions for store1 day 1
        5.times do
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store1,
            customer: customer,
            wallet: wallet,
            amount: 200.00,
            transaction_date: Date.parse('2025-08-15'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end

        # Create partial matching for store2 day 1 (amount matches but not count)
        8.times do # Wrong count (8 vs 10)
          customer = create(:customer)
          wallet = create(:wallet, owner: customer, wallet_type: 'customer')
          create(:transaction,
            store: store2,
            customer: customer,
            wallet: wallet,
            amount: 250.00, # Total 2000
            transaction_date: Date.parse('2025-08-15'),
            transaction_type: 'payment',
            status: 'completed'
          )
        end
      end

      it 'processes multiple stores and days correctly' do
        service_complex.call
        
        expect(service_complex.valid?).to be true
        expect(Reconciliation.count).to eq(2) # One per store
        expect(ReconciliationItem.count).to eq(5) # 5 CSV rows
      end

      it 'calculates correct summary for all stores' do
        service_complex.call
        
        summary = service_complex.summary_by_store
        
        expect(summary.length).to eq(2)
        
        # Store 1 should have 1 matched (day 1) and 2 unmatched (days 2,3)
        store1_summary = summary.find { |s| s[:store_id] == store1.id }
        expect(store1_summary[:matched_count]).to eq(1)
        expect(store1_summary[:unmatched_count]).to eq(2)
        
        # Store 2 should have 0 matched and 2 unmatched (no more partial state)
        store2_summary = summary.find { |s| s[:store_id] == store2.id }
        expect(store2_summary[:matched_count]).to eq(0)
        expect(store2_summary[:unmatched_count]).to eq(2)
      end

      it 'provides correct global totals' do
        service_complex.call
        
        # Only store1 day 1 matches (1000.00)
        expect(service_complex.matched_count).to eq(1)
        expect(service_complex.total_amount_matched).to be_within(0.01).of(1000.00)
        
        # Store1 days 2,3 are unmatched (no transactions)
        # Store2 day 1 is unmatched (amount matches but count doesn't - no partial state anymore)
        # Store2 day 2 is unmatched (no transactions)
        # Total: 4 unmatched
        expect(service_complex.unmatched_count).to eq(4)
      end
    end
  end

  describe '#processed_rows' do
    it 'tracks the number of processed CSV rows' do
      service.call
      expect(service.processed_rows).to eq(3)
    end
  end

  describe '#reconciliation_file' do
    it 'creates and attaches the file' do
      service.call
      
      file = service.reconciliation_file
      expect(file).to be_present
      expect(file.file_type).to eq('csv')
      expect(file.status).to eq('completed')
    end
  end

  describe '#reconciliations_by_store' do
    it 'maintains separate reconciliations for each store' do
      service.call
      
      reconciliations = service.reconciliations_by_store
      expect(reconciliations.keys).to contain_exactly(store1.id, store2.id)
      expect(reconciliations[store1.id]).to be_a(Reconciliation)
      expect(reconciliations[store2.id]).to be_a(Reconciliation)
    end
  end
end