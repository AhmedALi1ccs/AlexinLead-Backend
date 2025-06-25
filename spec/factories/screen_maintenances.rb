FactoryBot.define do
  factory :screen_maintenance do
    screen_inventory_id { 1 }
    sqm { "9.99" }
    maintenance_start_date { "2025-06-24" }
    maintenance_end_date { "2025-06-24" }
  end
end
