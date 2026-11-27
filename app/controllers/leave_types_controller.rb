class LeaveTypesController < ApplicationController
  before_action :require_hr!

  def index
    @leave_types = current_company.leave_types.ordered
    @stats = LeaveGrant.where(leave_type: @leave_types).group(:leave_type_id)
                       .pluck(:leave_type_id, Arel.sql("COUNT(*)"), Arel.sql("SUM(remaining_days)"))
                       .to_h { |id, count, remaining| [id, { count: count, remaining: remaining }] }
  end

  def new
    @leave_type = current_company.leave_types.new(grant_mode: "manual", expiration_policy: "none")
  end

  def create
    @leave_type = current_company.leave_types.new(leave_type_params.merge(grant_mode: "manual"))
    @leave_type.pool = @leave_type.code if @leave_type.pool.blank? || @leave_type.pool == "own"
    if @leave_type.save
      redirect_to leave_types_path, notice: "Tipo '#{@leave_type.name}' creado"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @leave_type = current_company.leave_types.find(params[:id])
  end

  def update
    @leave_type = current_company.leave_types.find(params[:id])
    attrs = @leave_type.system? ? leave_type_params.slice(:name) : leave_type_params.except(:code, :pool)
    if @leave_type.update(attrs)
      redirect_to leave_types_path, notice: "Tipo actualizado (los lotes ya cargados mantienen su vencimiento)"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def leave_type_params
    params.require(:leave_type).permit(:name, :code, :pool, :expiration_policy, :expiration_value, :active)
  end
end
