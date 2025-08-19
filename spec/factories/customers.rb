FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    document_number { "#{Faker::Number.number(digits: 8)}-#{Faker::Number.between(from: 0, to: 9)}" }
    phone { "+56 9 1234 5678" }
    status { "active" }
  end
end
