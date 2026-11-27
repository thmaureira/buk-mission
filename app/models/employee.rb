class Employee < ApplicationRecord
  ROLES = %w[hr manager employee].freeze

  belongs_to :company
  belongs_to :manager, class_name: "Employee", optional: true
  has_many :reports, class_name: "Employee", foreign_key: :manager_id, inverse_of: :manager
  has_many :leave_grants, dependent: :restrict_with_exception
  has_many :leave_periods, dependent: :restrict_with_exception
  has_many :ledger_entries, through: :leave_grants

  validates :first_name, :last_name, :rut, :hire_date, presence: true
  validates :role, inclusion: { in: ROLES }

  scope :active, -> { where(terminated_on: nil) }
  scope :ordered, -> { order(:last_name, :first_name) }

  def name = "#{first_name} #{last_name}"
  def initials = "#{first_name[0]}#{last_name[0]}".upcase
  def hr? = role == "hr"
  def manager? = role == "manager"

  # Date from which the ledger is the source of truth (after the Excel migration).
  def ledger_start_on = ledger_opened_on || hire_date

  def years_of_service(on: Date.current)
    years = on.year - hire_date.year
    years -= 1 if on < hire_date.next_year(years)
    [years, 0].max
  end

  # Anniversaries (1st, 2nd, ...) between two dates, inclusive.
  def anniversaries_between(from, to)
    (1..).lazy.map { |n| [n, hire_date.next_year(n)] }
                .take_while { |_, date| date <= to }
                .select { |_, date| date >= from }
                .to_a
  end

  def last_anniversary_on(on)
    years = years_of_service(on: on)
    years.zero? ? hire_date : hire_date.next_year(years)
  end
end
