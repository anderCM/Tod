FactoryBot.define do
  factory :wallet do
    balance { 100000 }
    status { "active" }

    trait :store_wallet do
      wallet_type { "store" }
      association :owner, factory: :store
    end

    trait :customer_wallet do
      wallet_type { "customer" }
      association :owner, factory: :customer
    end

    trait :with_balance do
      balance { 500000 }
    end

    trait :empty do
      balance { 0 }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :suspended do
      status { "suspended" }
    end
  end
end
