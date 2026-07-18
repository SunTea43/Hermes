class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_pundit_authorization

  def whatsapp
    adapter = WhatsappBot::Providers::Resolver.for_inbound(params[:provider])

    unless adapter.valid_signature?(request)
      head :forbidden
      return
    end

    inbound = adapter.parse_inbound(request)
    user = User.find_by(whatsapp_phone: inbound.from)

    if user.nil?
      WhatsappBot::Sender.deliver(
        inbound.from,
        "No encontré una cuenta asociada a este número. Registrate en #{ENV.fetch('APP_HOST', 'la app')}."
      )
    else
      WhatsappBot::DispatchService.call(user, inbound.body)
    end

    head :ok
  end
end
