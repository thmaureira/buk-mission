class EmployeesController < ApplicationController
  before_action :require_hr!

  def index
    @as_of = Date.current
    @employees = current_company.employees.includes(:manager).ordered
    @employees = @employees.where(area: params[:area]) if params[:area].present?
    if params[:q].present?
      q = "%#{params[:q]}%"
      @employees = @employees.where("first_name ILIKE :q OR last_name ILIKE :q OR rut ILIKE :q", q: q)
    end
    @balances = @employees.index_with { |e| Vacations::Balance.new(e, as_of: @as_of) }
    @areas = current_company.employees.distinct.order(:area).pluck(:area).compact
  end

  # Pestaña Vacaciones (como en Buk): saldo a una fecha, períodos y lotes.
  def show
    @employee = find_employee
    @as_of = parse_date(params[:as_of])
    @balance = Vacations::Balance.new(@employee, as_of: @as_of)
    # R1: proporcional devengado desde el último aniversario (aún no cargado).
    @proportional = VacationRules::Registry.resolve(:proportional_days, on: @as_of)
                                           .days(employee: @employee, on: @as_of)
    @periods = @employee.leave_periods.includes(:approver).chronological
    @grants = @employee.leave_grants.includes(:leave_type, :grant_batch, :ledger_entries)
                       .where("granted_on <= ?", @as_of).order(granted_on: :desc, id: :desc)
  end

  def summary
    @employee = find_employee
    @balance = Vacations::Balance.new(@employee)
    @next_anniversary = @employee.hire_date.next_year(@employee.years_of_service + 1)
    @progressive_next = VacationRules::Registry.resolve(:progressive_days, on: @next_anniversary)
                                               .days(employee: @employee, anniversary_on: @next_anniversary)
  end

  # R9: todos los movimientos, con quién, cuándo y por qué.
  def movements
    @employee = find_employee
    @entries = LedgerEntry.joins(:leave_grant).where(leave_grants: { employee_id: @employee.id })
                          .includes(:actor, :reversal, :reverses_entry, leave_grant: :leave_type)
                          .order(created_at: :desc, id: :desc)
    @inconsistent_grants = @employee.leave_grants.includes(:ledger_entries)
                                    .reject { |g| g.ledger_entries.sum(&:days) == g.remaining_days }
  end

  # R5: simulador de finiquito.
  def settlement
    @employee = find_employee
    @termination_on = parse_date(params[:termination_on])
    @result = Vacations::Settlement.call(employee: @employee, termination_on: @termination_on)
  end

  private

  def find_employee = current_company.employees.find(params[:id])
end
