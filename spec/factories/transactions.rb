FactoryBot.define do
  factory :transaction do
    association :wallet, :store_wallet
    association :store
    association :customer
    amount { 50000 }
    transaction_type { "payment" }
    description { "Payment for services" }
    sequence(:reference) { |n| "TRX-#{Date.current.strftime('%Y%m%d')}-#{n.to_s.rjust(6, '0')}" }
    status { "completed" }
    transaction_date { Time.current }
    
    trait :pending do
      status { "pending" }
    end
    
    trait :failed do
      status { "failed" }
    end
    
    trait :refund do
      transaction_type { "refund" }
      description { "Refund for cancelled order" }
    end
    
    trait :fee do
      transaction_type { "fee" }
      description { "Transaction fee" }
      amount { 1000 }
    end
    
    trait :deposit do
      transaction_type { "deposit" }
      description { "Wallet deposit" }
    end
    
    trait :large_amount do
      amount { 1000000 }
    end
    
    trait :old do
      transaction_date { 3.months.ago }
    end
    
    trait :recent do
      transaction_date { 1.day.ago }
    end
  end
end
