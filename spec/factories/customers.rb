FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    sequence(:document_number) { |n| "1234567#{n % 10}-9" }
    phone { "+56 9 1234 5678" }
    status { "active" }
  end
end
