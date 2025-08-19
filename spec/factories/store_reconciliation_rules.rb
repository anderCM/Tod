FactoryBot.define do
  factory :store_reconciliation_rule do
    association :store
    association :reconciliation_rule
    tolerance_value { 500 }
    priority { 10 }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
