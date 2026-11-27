class GrantBatchesController < ApplicationController
  before_action :require_hr!

  def index
    @batches = GrantBatch.where(company: current_company).includes(:leave_type, :created_by, :leave_grants)
                         .order(created_at: :desc)
  end

  def new
    @leave_types = current_company.leave_types.manual.active.ordered
    @employees = current_company.employees.active.ordered
    @areas = @employees.map(&:area).compact.uniq.sort
    @selected_type = @leave_types.find_by(id: params[:leave_type_id])
  end

  def create
    leave_type = current_company.leave_types.manual.find(params[:leave_type_id])
    employees, target = resolve_targets
    batch = Vacations::BulkGrant.call(
      leave_type: leave_type, employees: employees, days: params[:days].to_s.tr(",", "."),
      granted_on: parse_date(params[:granted_on]), reason: params[:reason],
      actor: current_actor, target_description: target
    )
    redirect_to grant_batch_path(batch), notice: "Carga aplicada a #{employees.size} colaborador(es)"
  end

  def show
    @batch = GrantBatch.where(company: current_company).find(params[:id])
    @grants = @batch.leave_grants.includes(:employee, :ledger_entries)
  end

  private

  def resolve_targets
    active = current_company.employees.active
    case params[:target]
    when "all" then [active.to_a, "Todos los colaboradores"]
    when "area" then [active.where(area: params[:area]).to_a, "Área: #{params[:area]}"]
    else
      selected = active.where(id: params[:employee_ids]).to_a
      [selected, selected.map(&:name).to_sentence(locale: :es)]
    end
  end
end
