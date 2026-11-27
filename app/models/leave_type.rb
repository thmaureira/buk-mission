class LeaveType < ApplicationRecord
  GRANT_MODES = %w[rule manual].freeze
  EXPIRATION_POLICIES = %w[none fixed_date relative].freeze
  POOLS = { "vacation" => "Vacaciones", "administrative" => "Días administrativos" }.freeze

  belongs_to :company
  has_many :leave_grants, dependent: :restrict_with_exception
  has_many :grant_batches, dependent: :restrict_with_exception

  validates :name, :code, :pool, presence: true
  validates :code, uniqueness: { scope: :company_id }, format: { with: /\A[a-z0-9_]+\z/ }
  validates :grant_mode, inclusion: { in: GRANT_MODES }
  validates :expiration_policy, inclusion: { in: EXPIRATION_POLICIES }
  validates :expiration_value, presence: true, unless: -> { expiration_policy == "none" }
  validates :expiration_value, format: { with: /\A\d{2}-\d{2}\z/, message: "debe tener formato MM-DD" },
                               if: -> { expiration_policy == "fixed_date" }
  validates :expiration_value, format: { with: /\A\d+[dmy]\z/, message: "debe tener formato 90d, 6m o 2y" },
                               if: -> { expiration_policy == "relative" }

  scope :ordered, -> { order(:position, :name) }
  scope :manual, -> { where(grant_mode: "manual") }
  scope :active, -> { where(active: true) }

  def self.pool_label(pool) = POOLS[pool] || find_by(code: pool)&.name || pool.to_s.humanize
  def pool_label = self.class.pool_label(pool)
  def rule? = grant_mode == "rule"

  # Expiration date for a lot granted on `granted_on`.
  def expiration_for(granted_on)
    case expiration_policy
    when "none" then nil
    when "fixed_date"
      month, day = expiration_value.split("-").map(&:to_i)
      date = Date.new(granted_on.year, month, day)
      date < granted_on ? date.next_year : date
    when "relative"
      amount = expiration_value.to_i
      case expiration_value[-1]
      when "d" then granted_on + amount.days
      when "m" then granted_on >> amount
      when "y" then granted_on.next_year(amount)
      end
    end
  end

  def expiration_description
    case expiration_policy
    when "none" then "No vence"
    when "fixed_date" then "Vence cada #{expiration_value.split('-').reverse.join('/')}"
    when "relative"
      unit = { "d" => "días", "m" => "meses", "y" => "años" }[expiration_value[-1]]
      "Vence #{expiration_value.to_i} #{unit} después de la carga"
    end
  end
end
