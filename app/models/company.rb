class Company < ApplicationRecord
  has_many :employees, dependent: :restrict_with_exception
  has_many :leave_types, dependent: :restrict_with_exception
end
