class GrantBatch < ApplicationRecord
  belongs_to :company
  belongs_to :leave_type
  belongs_to :created_by, class_name: "Employee"
  has_many :leave_grants, dependent: :restrict_with_exception

  validates :days, numericality: { greater_than: 0 }
  validates :reason, :granted_on, presence: true
end
