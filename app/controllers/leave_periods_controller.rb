# Registro de vacaciones aprobadas. En Buk el flujo de solicitud/aprobación ya existe;
# aquí se simula el evento "solicitud aprobada" que dispara Vacations::ApproveRequest.
class LeavePeriodsController < ApplicationController
  before_action :require_hr!

  def new
    @employee = current_company.employees.find(params[:employee_id])
    @balance = Vacations::Balance.new(@employee)
    @pools = @employee.leave_grants.joins(:leave_type).distinct.pluck("leave_types.pool")
    @pools = ["vacation"] if @pools.empty?
  end

  def create
    employee = current_company.employees.find(params[:employee_id])
    period = Vacations::ApproveRequest.call(
      employee: employee,
      start_date: parse_date(params[:start_date], nil),
      end_date: parse_date(params[:end_date], nil),
      pool: params[:pool].presence || "vacation",
      approver: employee.manager || current_actor,
      note: params[:note]
    )
    redirect_to employee_path(employee), notice: "Vacaciones registradas: #{period.business_days.to_i} días hábiles descontados"
  end

  def cancel
    period = LeavePeriod.joins(:employee).where(employees: { company_id: current_company.id }).find(params[:id])
    Vacations::CancelRequest.call(leave_period: period, actor: current_actor, reason: params[:reason])
    redirect_to employee_path(period.employee), notice: "Período anulado; los días volvieron a sus lotes"
  end
end
