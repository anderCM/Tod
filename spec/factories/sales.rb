FactoryBot.define do
  factory :sale do
    association :store
    association :customer
    sequence(:sale_number) { |n| "SALE-#{Date.current.strftime('%Y%m%d')}-#{n.to_s.rjust(4, '0')}" }
    total_amount { 100000 }
    sale_date { Time.current }
    status { "completed" }
    description { "Test sale" }
  end
end
