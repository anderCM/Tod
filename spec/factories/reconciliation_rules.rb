FactoryBot.define do
  factory :reconciliation_rule do
    sequence(:name) { |n| "Rule #{n}" }
    description { "Test reconciliation rule" }
    rule_type { "amount" }
    priority { 1 }
    default_tolerance_value { 100 }
    active { true }

    trait :exact do
      rule_type { "exact" }
      default_tolerance_value { 0 }
      description { "Exact match rule" }
    end

    trait :date do
      rule_type { "date" }
      default_tolerance_value { 7 }
      description { "Date tolerance rule (days)" }
    end

    trait :percentage do
      rule_type { "percentage" }
      default_tolerance_value { 5 }
      description { "Percentage tolerance rule" }
    end

    trait :amount do
      rule_type { "amount" }
      default_tolerance_value { 1000 }
      description { "Amount tolerance rule" }
    end

    trait :inactive do
      active { false }
    end
  end
end
