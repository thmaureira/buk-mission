# R7: el colaborador ve sus días disponibles e historial, sin el detalle del cálculo.
class MyBalancesController < ApplicationController
  def show
    @employee = current_actor
    @balance = Vacations::Balance.new(@employee)
    @periods = @employee.leave_periods.active.includes(:approver).chronological
  end
end
