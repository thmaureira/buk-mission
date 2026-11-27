class AdjustmentsController < ApplicationController
  before_action :require_hr!
  before_action :set_employee

  def new
    @leave_types = current_company.leave_types.active.ordered
    @token = SecureRandom.uuid
  end

  def create
    leave_type = current_company.leave_types.find(params[:leave_type_id])
    Vacations::Adjust.call(
      employee: @employee, leave_type: leave_type, days: params[:days].to_s.tr(",", "."),
      reason: params[:reason], actor: current_actor, token: params[:token]
    )
    redirect_to employee_path(@employee), notice: "Ajuste registrado en el libro"
  end

  private

  def set_employee = @employee = current_company.employees.find(params[:employee_id])
end
