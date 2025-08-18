FactoryBot.define do
  factory :store do
    sequence(:name) { |n| "Store #{n}" }
    sequence(:tax_id) { |n| "1234567#{n % 10}-9" }
    sequence(:email) { |n| "store#{n}@example.com" }
    phone { "+56 9 1234 5678" }
    password { "password123" }
    password_confirmation { "password123" }
    status { "active" }
    sequence(:authentication_token) { |n| "token_#{n}_#{SecureRandom.hex(32)}" }
  end
end
