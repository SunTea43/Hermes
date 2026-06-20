class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_pundit_authorization

  def whatsapp
    from    = params[:From].to_s.delete_prefix("whatsapp:")
    body    = params[:Body].to_s.strip
    user    = User.find_by(whatsapp_phone: from)

    if user.nil?
      WhatsappBot::Sender.deliver(from, "No encontré una cuenta asociada a este número. Registrate en #{ENV.fetch('APP_HOST', 'la app')}.")
    else
      WhatsappBot::DispatchService.call(user, body)
    end

    head :ok
  end
end
