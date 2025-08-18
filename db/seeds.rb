# frozen_string_literal: true

puts "🌱 Creando datos de prueba para el sistema de conciliación..."

default_password = 'Conectado$25'
puts "📦 Creando tiendas..."
stores = [
  {
    name: "Supermercado Central",
    description: "Cadena de supermercados líder en la región",
    status: "active",
    tax_id: "12345678-9",
    address: "Av. Principal 123, Ciudad",
    phone: "+56 2 2345 6789",
    email: "contacto@supercentral.cl",
    password: default_password,
    password_confirmation: default_password,
  },
  {
    name: "Farmacia Salud",
    description: "Farmacia de barrio con atención personalizada",
    status: "active",
    tax_id: "23456789-0",
    address: "Calle Comercial 456, Ciudad",
    phone: "+56 2 3456 7890",
    email: "info@farmaciasalud.cl",
    password: default_password,
    password_confirmation: default_password,
  },
  {
    name: "Restaurante El Buen Sabor",
    description: "Restaurante familiar con comida casera",
    status: "active",
    tax_id: "34567890-1",
    address: "Plaza Mayor 789, Ciudad",
    phone: "+56 2 4567 8901",
    email: "reservas@buensabor.cl",
    password: default_password,
    password_confirmation: default_password,
  },
  {
    name: "Tienda de Ropa Moda Express",
    description: "Tienda de ropa con las últimas tendencias",
    status: "active",
    tax_id: "45678901-2",
    address: "Mall Central Local 15, Ciudad",
    phone: "+56 2 5678 9012",
    email: "ventas@modaexpress.cl",
    password: default_password,
    password_confirmation: default_password,
  },
  {
    name: "Gasolinera Rápida",
    description: "Estación de servicio 24/7",
    status: "active",
    tax_id: "56789012-3",
    address: "Autopista Norte Km 25, Ciudad",
    phone: "+56 2 6789 0123",
    email: "admin@gasolinerarapida.cl",
    password: default_password,
    password_confirmation: default_password,
  },
]

stores.each do |store_data|
  Store.create!(store_data)
end

puts "✅ #{Store.count} tiendas creadas"

puts "👥 Creando clientes..."
customers = [
  {
    name: "María González",
    email: "maria.gonzalez@email.com",
    phone: "+56 9 1234 5678",
    document_number: "12345678-9",
    status: "active",
  },
  {
    name: "Juan Pérez",
    email: "juan.perez@email.com",
    phone: "+56 9 2345 6789",
    document_number: "23456789-0",
    status: "active",
  },
  {
    name: "Ana Silva",
    email: "ana.silva@email.com",
    phone: "+56 9 3456 7890",
    document_number: "34567890-1",
    status: "active",
  },
  {
    name: "Carlos Rodríguez",
    email: "carlos.rodriguez@email.com",
    phone: "+56 9 4567 8901",
    document_number: "45678901-2",
    status: "active",
  },
  {
    name: "Laura Martínez",
    email: "laura.martinez@email.com",
    phone: "+56 9 5678 9012",
    document_number: "56789012-3",
    status: "active",
  },
  {
    name: "Roberto López",
    email: "roberto.lopez@email.com",
    phone: "+56 9 6789 0123",
    document_number: "67890123-4",
    status: "active",
  },
  {
    name: "Carmen Torres",
    email: "carmen.torres@email.com",
    phone: "+56 9 7890 1234",
    document_number: "78901234-5",
    status: "active",
  },
  {
    name: "Diego Herrera",
    email: "diego.herrera@email.com",
    phone: "+56 9 8901 2345",
    document_number: "89012345-6",
    status: "active",
  },
]

customers.each do |customer_data|
  Customer.create!(customer_data)
end

puts "✅ #{Customer.count} clientes creados"

puts "💼 Creando billeteras de tiendas..."
Store.all.each do |store|
  Wallet.create!(
    balance: rand(100000..500000),
    owner: store,
    wallet_type: "store",
    status: "active",
  )
end

puts "💼 Creando billeteras de clientes..."
Customer.all.each do |customer|
  Wallet.create!(
    balance: 0,
    owner: customer,
    wallet_type: "customer",
    status: "active",
  )
end

puts "✅ #{Wallet.count} billeteras creadas"

puts "💰 Creando depósitos iniciales..."
Customer.all.each do |customer|
  customer_wallet = customer.wallets.first
  deposit_amount = rand(300000..1000000)

  Transaction.create!(
    amount: deposit_amount,
    transaction_type: "deposit",
    description: "Depósito inicial a billetera",
    reference: "DEP-#{SecureRandom.hex(6).upcase}",
    status: "completed",
    wallet: customer_wallet,
    store: Store.all.sample,
    customer: customer,
    transaction_date: rand(60.days.ago..30.days.ago),
  )

  customer_wallet.update!(balance: deposit_amount)
end

puts "✅ #{Transaction.where(transaction_type: "deposit").count} depósitos creados"

puts "💰 Creando transacciones adicionales (fallidas y pendientes)..."

Store.all.each do |store|
  rand(1..2).times do
    customer = Customer.all.sample
    customer_wallet = customer.wallets.first

    Transaction.create!(
      amount: rand(5000..25000),
      transaction_type: "payment",
      description: "Pago fallido en #{store.name}",
      reference: "TXN-#{SecureRandom.hex(6).upcase}",
      status: "failed",
      wallet: customer_wallet,
      store: store,
      customer: customer,
      transaction_date: rand(30.days.ago..Time.current),
    )
  end

  rand(1..2).times do
    customer = Customer.all.sample
    customer_wallet = customer.wallets.first

    Transaction.create!(
      amount: rand(5000..20000),
      transaction_type: "payment",
      description: "Pago pendiente en #{store.name}",
      reference: "TXN-#{SecureRandom.hex(6).upcase}",
      status: "pending",
      wallet: customer_wallet,
      store: store,
      customer: customer,
      transaction_date: rand(7.days.ago..Time.current),
    )
  end
end

puts "🔄 Creando transacciones de reembolso..."
completed_transactions = Transaction.where(status: "completed", transaction_type: "payment").sample(3)

completed_transactions.each do |original_transaction|
  refund_amount = original_transaction.amount * 0.3

  Transaction.create!(
    amount: refund_amount,
    transaction_type: "refund",
    description: "Reembolso parcial de #{original_transaction.description}",
    reference: "REF-#{SecureRandom.hex(6).upcase}",
    status: "completed",
    wallet: original_transaction.wallet,
    store: original_transaction.store,
    customer: original_transaction.customer,
    transaction_date: rand(original_transaction.transaction_date..Time.current),
  )

  original_transaction.wallet.update!(balance: original_transaction.wallet.balance + refund_amount)
  original_transaction.store.wallets.first.update!(balance: original_transaction.store.wallets.first.balance - refund_amount)
end

puts "✅ #{Transaction.count} transacciones creadas"

puts "🛒 Creando ventas y transacciones correlacionadas..."

Store.all.each do |store|
  store_wallet = store.wallets.first
  
  Customer.all.sample(rand(2..4)).each do |customer|
    customer_wallet = customer.wallets.first
    
    # Crear venta
    sale_amount = rand(5000..30000)
    sale_date = rand(30.days.ago..Time.current)
    
    sale = Sale.create!(
      store: store,
      customer: customer,
      total_amount: sale_amount,
      sale_date: sale_date,
      status: "completed",
      description: "Venta en #{store.name}"
    )
    
    # Verificar que el cliente tenga suficiente balance
    next if customer_wallet.balance < sale_amount
    
    # Crear transacción de pago correspondiente
    Transaction.create!(
      amount: sale_amount,
      transaction_type: "payment",
      description: "Pago por venta #{sale.sale_number} en #{store.name}",
      reference: "TXN-#{SecureRandom.hex(6).upcase}",
      status: "completed",
      wallet: customer_wallet,
      store: store,
      customer: customer,
      transaction_date: sale_date,
    )
    
    # Actualizar balances
    customer_wallet.update!(balance: customer_wallet.balance - sale_amount)
    store_wallet.update!(balance: store_wallet.balance + sale_amount)
  end
end

puts "✅ #{Sale.count} ventas creadas"
puts "✅ #{Transaction.where(transaction_type: "payment").count} transacciones de pago creadas"

reconciliation_rules = [
  {
    name: "Match Exacto",
    description: "Coincidencia exacta de monto y fecha",
    rule_type: 'exact',
    default_tolerance_value: 0,
    priority: 1,
    active: true,
  },
  {
    name: "Tolerancia por días",
    description: "Permite días de diferencia en fecha (monto exacto)",
    rule_type: 'date',
    default_tolerance_value: 1,
    priority: 2,
    active: true,
  },
  {
    name: "Tolerancia porcentual de monto",
    description: "Permite hasta un porcentaje de diferencia en monto",
    rule_type: 'percentage',
    default_tolerance_value: 0.5,
    priority: 3,
    active: true,
  },
  {
    name: "Tolerancia de monto fijo",
    description: "Permite hasta un monto de diferencia",
    rule_type: 'amount',
    default_tolerance_value: 100,
    priority: 4,
    active: true,
  }
]

puts "🔧 Creando reglas de reconciliación..."
reconciliation_rules.each do |rule_data|
  ReconciliationRule.create!(rule_data)
end

puts "\n📊 RESUMEN DE DATOS CREADOS:"
puts "   • Tiendas: #{Store.count}"
puts "   • Clientes: #{Customer.count}"
puts "   • Billeteras: #{Wallet.count}"
puts "   • Transacciones: #{Transaction.count}"
puts "   • Ventas: #{Sale.count}"
puts "   • Depósitos: #{Transaction.where(transaction_type: "deposit").count}"
puts "   • Pagos: #{Transaction.where(transaction_type: "payment").count}"
puts "   • Reembolsos: #{Transaction.where(transaction_type: "refund").count}"
puts "   • Reglas: #{ReconciliationRule.count}"