FactoryBot.define do
  factory :item do
    name { "MyString" }
    description { "MyText" }
    category { "MyString" }
    location { "MyString" }
    quantity { 1 }
    status { "MyString" }
    user { nil }
    disposed_at { "2025-06-02 17:04:29" }
    disposal_reason { "MyText" }
  end
end
