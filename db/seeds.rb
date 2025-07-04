# frozen_string_literal: true

# Datos de prueba para el sistema de conciliación
# Este archivo crea tiendas, clientes, billeteras y transacciones de ejemplo
# para que el desarrollador pueda implementar el proceso de conciliación

puts "🌱 Creando datos de prueba para el sistema de conciliación..."

# Crear tiendas
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
  },
  {
    name: "Farmacia Salud",
    description: "Farmacia de barrio con atención personalizada",
    status: "active",
    tax_id: "23456789-0",
    address: "Calle Comercial 456, Ciudad",
    phone: "+56 2 3456 7890",
    email: "info@farmaciasalud.cl",
  },
  {
    name: "Restaurante El Buen Sabor",
    description: "Restaurante familiar con comida casera",
    status: "active",
    tax_id: "34567890-1",
    address: "Plaza Mayor 789, Ciudad",
    phone: "+56 2 4567 8901",
    email: "reservas@buensabor.cl",
  },
  {
    name: "Tienda de Ropa Moda Express",
    description: "Tienda de ropa con las últimas tendencias",
    status: "active",
    tax_id: "45678901-2",
    address: "Mall Central Local 15, Ciudad",
    phone: "+56 2 5678 9012",
    email: "ventas@modaexpress.cl",
  },
  {
    name: "Gasolinera Rápida",
    description: "Estación de servicio 24/7",
    status: "active",
    tax_id: "56789012-3",
    address: "Autopista Norte Km 25, Ciudad",
    phone: "+56 2 6789 0123",
    email: "admin@gasolinerarapida.cl",
  },
]

stores.each do |store_data|
  Store.create!(store_data)
end

puts "✅ #{Store.count} tiendas creadas"

# Crear clientes
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

# Crear billeteras para tiendas
puts "💼 Creando billeteras de tiendas..."
Store.all.each do |store|
  Wallet.create!(
    balance: rand(100000..500000),
    owner: store,
    wallet_type: "store",
    status: "active",
  )
end

# Crear billeteras para clientes
puts "💼 Creando billeteras de clientes..."
Customer.all.each do |customer|
  Wallet.create!(
    balance: 0, # Empezar con balance 0
    owner: customer,
    wallet_type: "customer",
    status: "active",
  )
end

puts "✅ #{Wallet.count} billeteras creadas"

# Crear depósitos iniciales a las billeteras de clientes
puts "💰 Creando depósitos iniciales..."
Customer.all.each do |customer|
  customer_wallet = customer.wallets.first
  deposit_amount = rand(300000..1000000) # Depósitos entre $300k y $1M

  # Transacción de depósito
  Transaction.create!(
    amount: deposit_amount,
    transaction_type: "deposit",
    description: "Depósito inicial a billetera",
    reference: "DEP-#{SecureRandom.hex(6).upcase}",
    status: "completed",
    wallet: customer_wallet,
    store: Store.all.sample, # Asignar a una tienda aleatoria
    customer: customer,
    transaction_date: rand(60.days.ago..30.days.ago), # Depósitos hace 30-60 días
  )

  # Actualizar balance
  customer_wallet.update!(balance: deposit_amount)
end

puts "✅ #{Transaction.where(transaction_type: "deposit").count} depósitos creados"

# Crear transacciones de ejemplo
puts "💰 Creando transacciones de ejemplo..."

# Crear transacciones para cada tienda
Store.all.each do |store|
  store_wallet = store.wallets.first

  # Transacciones de pago (clientes pagando a tiendas)
  Customer.all.sample(rand(3..6)).each do |customer|
    customer_wallet = customer.wallets.first
    amount = rand(5000..30000) # Montos más pequeños

    # Verificar que el cliente tenga suficiente balance
    next if customer_wallet.balance < amount

    # Transacción de pago
    Transaction.create!(
      amount: amount,
      transaction_type: "payment",
      description: "Pago por compra en #{store.name}",
      reference: "TXN-#{SecureRandom.hex(6).upcase}",
      status: "completed",
      wallet: customer_wallet,
      store: store,
      customer: customer,
      transaction_date: rand(30.days.ago..Time.current),
    )

    # Actualizar balances
    customer_wallet.update!(balance: customer_wallet.balance - amount)
    store_wallet.update!(balance: store_wallet.balance + amount)
  end

  # Algunas transacciones fallidas
  rand(1..3).times do
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

  # Algunas transacciones pendientes
  rand(1..2).times do
    customer = Customer.all.sample
    customer_wallet = customer.wallets.first

    Transaction.create!(
      amount: rand(5000..20000), # Montos más pequeños
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

# Crear algunas transacciones de reembolso
puts "🔄 Creando transacciones de reembolso..."
completed_transactions = Transaction.where(status: "completed", transaction_type: "payment").sample(3) # Solo de pagos

completed_transactions.each do |original_transaction|
  refund_amount = original_transaction.amount * 0.3 # Reembolso más pequeño (30%)

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

  # Actualizar balances
  original_transaction.wallet.update!(balance: original_transaction.wallet.balance + refund_amount)
  original_transaction.store.wallets.first.update!(balance: original_transaction.store.wallets.first.balance - refund_amount)
end

puts "✅ #{Transaction.count} transacciones creadas"

# Mostrar resumen final
puts "\n📊 RESUMEN DE DATOS CREADOS:"
puts "   • Tiendas: #{Store.count}"
puts "   • Clientes: #{Customer.count}"
puts "   • Billeteras: #{Wallet.count}"
puts "   • Transacciones: #{Transaction.count}"
puts "   • Depósitos: #{Transaction.where(transaction_type: "deposit").count}"
puts "   • Pagos: #{Transaction.where(transaction_type: "payment").count}"
puts "   • Reembolsos: #{Transaction.where(transaction_type: "refund").count}"
puts "\n💡 El desarrollador ahora puede implementar el proceso de conciliación"
puts "   usando estos datos de prueba como base."
