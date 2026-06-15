class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  after_action :verify_pundit_authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    redirect_back fallback_location: root_path, alert: "You are not authorized to perform this action."
  end

  def verify_pundit_authorization
    return if devise_controller?

    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end
end
