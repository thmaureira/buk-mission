# The jobs run on their own with Sidekiq-cron; this screen runs them by hand
# (even twice) to show that they are idempotent.
class ScheduledJobsController < ApplicationController
  before_action :require_hr!

  JOBS = {
    "anniversary_grants" => ["Carga de aniversarios", "R2 · R3", "AnniversaryGrantsJob"],
    "expirations" => ["Vencimientos", "R11", "ExpirationsJob"],
    "mark_taken" => ["Paso a tomadas", "R4", "MarkTakenJob"]
  }.freeze

  def index
    @jobs = JOBS
    @recent = LedgerEntry.where(source: %w[job:anniversary job:expirations])
                         .includes(leave_grant: [:employee, :leave_type]).order(created_at: :desc).limit(25)
    @holidays = Holiday.where(date: Date.current.beginning_of_year..Date.current.next_year.end_of_year).order(:date)
    @rule_versions = RuleVersion.order(:rule_key, :effective_from)
  end

  def run
    name, _, klass = JOBS.fetch(params[:job])
    before = LedgerEntry.count
    result = klass.constantize.perform_now
    created = LedgerEntry.count - before
    message = if params[:job] == "mark_taken"
                "#{name}: #{result} período(s) pasaron a tomadas"
              else
                "#{name}: #{created} movimiento(s) nuevo(s)#{' — nada pendiente, no se cargó doble' if created.zero?}"
              end
    redirect_to scheduled_jobs_path, notice: message
  end
end
