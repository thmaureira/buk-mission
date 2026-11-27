class OpeningBalanceImportsController < ApplicationController
  before_action :require_hr!
  before_action :set_import, only: [:show, :approve, :reject]

  def index
    @imports = OpeningBalanceImport.where(company: current_company).includes(:uploaded_by, :approved_by, :rows)
                                   .order(created_at: :desc)
  end

  def new; end

  def create
    file = params[:file]
    raise Ledger::Error, "Debe adjuntar el archivo CSV exportado del Excel" if file.blank?

    import = OpeningBalances::Parse.call(
      company: current_company, uploaded_by: current_actor, content: file.read,
      filename: file.original_filename, cutoff_on: parse_date(params[:cutoff_on], nil)
    )
    redirect_to opening_balance_import_path(import), notice: "Archivo leído. Revise el reporte de diferencias antes de aprobar."
  end

  def show
    @rows = @import.rows.includes(:employee)
  end

  def approve
    OpeningBalances::Approve.call(import: @import, actor: current_actor)
    redirect_to opening_balance_import_path(@import), notice: "Migración aprobada: saldos de apertura cargados en el libro"
  end

  def reject
    raise Ledger::Error, "La migración ya fue procesada" unless @import.pending?

    @import.update!(status: "rejected")
    redirect_to opening_balance_imports_path, notice: "Migración rechazada; no se cargó ningún movimiento"
  end

  private

  def set_import = @import = OpeningBalanceImport.where(company: current_company).find(params[:id])
end
