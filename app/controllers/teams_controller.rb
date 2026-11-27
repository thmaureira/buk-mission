# R8: HR and managers see the days each employee took and who approved them.
class TeamsController < ApplicationController
  before_action :require_manager_or_hr!

  def show
    scope = current_actor.hr? ? current_company.employees : current_actor.reports
    @employees = scope.ordered
    @employee_filter = @employees.find_by(id: params[:employee_id])
    @year = (params[:year].presence || Date.current.year).to_i
    @periods = LeavePeriod.where(employee: @employee_filter || @employees)
                          .where("EXTRACT(YEAR FROM start_date) = ?", @year)
                          .includes(:employee, :approver).chronological
    @balances = @employees.index_with { |e| Vacations::Balance.new(e) }
  end
end
