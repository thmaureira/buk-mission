# Records every request the app handles, for the usage metrics screen.
# Requests stopped by Basic Auth never reach the action, so they are not counted.
module TracksPageViews
  extend ActiveSupport::Concern

  EXTERNAL_HOSTS = /\.ngrok(-free)?\.(app|dev|io)\z/

  included do
    after_action :track_page_view
  end

  private

  def track_page_view
    PageView.create!(
      visitor_id: visitor_id, actor: current_actor, actor_role: current_actor&.role,
      request_method: request.method, path: request.path, controller_action: "#{controller_name}##{action_name}",
      status: response.status, external: request.host.match?(EXTERNAL_HOSTS)
    )
  rescue StandardError => e
    Rails.logger.warn("page view not recorded: #{e.message}")
  end

  def visitor_id
    cookies.permanent.signed[:visitor_id] ||= SecureRandom.uuid
  end
end
