# R7: employees see their available days and history, without the calculation details.
class MyBalancesController < ApplicationController
  def show
    @employee = current_actor
    @balance = Vacations::Balance.new(@employee)
    @periods = @employee.leave_periods.active.includes(:approver).chronological
  end
end
