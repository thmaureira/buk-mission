FactoryBot.define do
  factory :company do
    name { "Tellin SpA" }
  end

  factory :employee do
    company
    first_name { "Camila" }
    sequence(:last_name) { |n| "Fuentes#{n}" }
    sequence(:rut) { |n| "#{10_000_000 + n}-#{n % 10}" }
    hire_date { Date.new(2020, 3, 2) }
    role { "employee" }
  end
end
