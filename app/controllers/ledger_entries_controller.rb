class LedgerEntriesController < ApplicationController
  before_action :require_hr!

  def reverse
    entry = LedgerEntry.joins(leave_grant: :employee)
                       .where(employees: { company_id: current_company.id }).find(params[:id])
    if entry.leave_period && entry.kind == "usage"
      raise Ledger::Error, "Para revertir un uso de vacaciones, anule el período completo"
    end

    Ledger::Reverse.call(entry: entry, actor: current_actor, reason: params[:reason])
    redirect_to movements_employee_path(entry.leave_grant.employee), notice: "Movimiento revertido"
  end
end
