FactoryBot.define do
  factory :company do
    name { "Tellin SpA" }
  end

  factory :leave_type do
    company
    sequence(:code) { |n| "type_#{n}" }
    name { code.humanize }
    pool { "vacation" }

    trait :legal do
      code { "legal" }
      name { "Legales" }
      grant_mode { "rule" }
      expiration_policy { "relative" }
      expiration_value { "2y" }
      system { true }
    end

    trait :progressive do
      code { "progressive" }
      name { "Progresivas" }
      grant_mode { "rule" }
      expiration_policy { "relative" }
      expiration_value { "2y" }
      system { true }
    end

    trait :administrative do
      code { "administrative" }
      name { "Días Administrativos" }
      pool { "administrative" }
      expiration_policy { "fixed_date" }
      expiration_value { "12-31" }
    end
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
