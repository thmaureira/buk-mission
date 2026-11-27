class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_actor, :can_view_employee?

  rescue_from Ledger::Error do |error|
    redirect_back fallback_location: root_path, alert: error.message
  end

  private

  # POC: there is no login; the current user is picked with "Ver como" (session[:actor_id]).
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
