class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  # Protección opcional para cuando la app se expone con ngrok: si están definidas
  # BASIC_AUTH_USER y BASIC_AUTH_PASSWORD se exige HTTP Basic Auth en todas las páginas.
  before_action :basic_auth_for_tunnel, if: -> { ENV["BASIC_AUTH_USER"].present? && ENV["BASIC_AUTH_PASSWORD"].present? }

  helper_method :current_actor, :can_view_employee?

  rescue_from Ledger::Error do |error|
    redirect_back fallback_location: root_path, alert: error.message
  end

  private

  def basic_auth_for_tunnel
    http_basic_authenticate_or_request_with(
      name: ENV.fetch("BASIC_AUTH_USER"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
      realm: "Gestor de Vacaciones POC"
    )
  end

  # POC: no hay login; el usuario actual se elige con "Ver como" (session[:actor_id]).
  def current_actor
    @current_actor ||= Employee.find_by(id: session[:actor_id]) || Employee.find_by(role: "hr")
  end

  def current_company = current_actor.company

  def require_hr!
    redirect_to root_path, alert: "Solo RRHH puede acceder a esta sección" unless current_actor.hr?
  end

  def require_manager_or_hr!
    redirect_to root_path, alert: "Solo jefaturas y RRHH" unless current_actor.hr? || current_actor.manager?
  end

  def can_view_employee?(employee)
    current_actor.hr? || employee.manager_id == current_actor.id
  end

  def parse_date(value, default = Date.current)
    value.present? ? Date.parse(value) : default
  rescue Date::Error
    default
  end
end
