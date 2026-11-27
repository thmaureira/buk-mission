# Usage metrics for the POC: visits (GET), actions (POST/PATCH) and unique visitors.
class MetricsController < ApplicationController
  before_action :require_hr!

  SCREENS = {
    "employees#index" => "Colaboradores", "employees#show" => "Ficha · Vacaciones",
    "employees#summary" => "Ficha · Resumen", "employees#movements" => "Ficha · Movimientos",
    "employees#settlement" => "Ficha · Finiquito", "leave_periods#new" => "Registrar vacaciones",
    "adjustments#new" => "Ajuste manual", "my_balances#show" => "Mi saldo", "teams#show" => "Historial del equipo",
    "leave_types#index" => "Tipos de días", "grant_batches#index" => "Cargas", "grant_batches#new" => "Nueva carga",
    "opening_balance_imports#index" => "Migración Excel", "opening_balance_imports#show" => "Reporte de migración",
    "scheduled_jobs#index" => "Procesos", "metrics#show" => "Métricas de uso"
  }.freeze
  DAYS = 14

  def show
    visits = PageView.visits
    @totals = {
      visits: visits.count, visitors: PageView.distinct.count(:visitor_id),
      external: visits.where(external: true).count, actions: PageView.actions.count,
      today: visits.since(Time.current.beginning_of_day).count
    }
    local_day = Arel.sql("DATE(created_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}')")
    by_day = visits.since(DAYS.days.ago.beginning_of_day).group(local_day)
    counts = by_day.count
    uniques = by_day.distinct.count(:visitor_id)
    @days = (0...DAYS).map { |i| Date.current - i }.map { |d| [d, counts[d].to_i, uniques[d].to_i] }
    @max_day = [@days.map(&:second).max, 1].max
    @screens = visits.group(:controller_action).order(count_all: :desc).limit(12).count
    @roles = visits.group(:actor_role).count
    @recent = PageView.includes(:actor).order(created_at: :desc).limit(30)
  end

  helper_method def screen_label(key) = SCREENS.fetch(key, key)
end
