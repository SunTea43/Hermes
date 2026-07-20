class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_pundit_authorization

  def whatsapp
    adapter = WhatsappBot::Providers::Resolver.for_inbound(params[:provider])

    if request.get? || request.head?
      return verify_whatsapp_subscription(adapter)
    end

    unless adapter.valid_signature?(request)
      head :forbidden
      return
    end

    inbound = adapter.parse_inbound(request)
    if inbound.nil?
      head :ok
      return
    end

    user = User.find_by(whatsapp_phone: inbound.from)
    audit = create_audit(inbound, user)

    if user.nil?
      deny_unknown_user(inbound, audit)
    else
      dispatch_for_user(user, inbound, audit)
    end

    head :ok
  end

  private

  def verify_whatsapp_subscription(adapter)
    unless adapter.respond_to?(:verify_subscription)
      head :method_not_allowed
      return
    end

    challenge = adapter.verify_subscription(request)
    if challenge
      render plain: challenge, status: :ok
    else
      head :forbidden
    end
  end

  def create_audit(inbound, user)
    WhatsappMessageAudit.create!(
      user: user,
      provider: inbound.provider.to_s,
      provider_message_id: inbound.provider_message_id,
      from_phone: inbound.from,
      body: inbound.body,
      status: "received",
      metadata: { to: inbound.to }
    )
  end

  def deny_unknown_user(inbound, audit)
    message = "No encontré una cuenta asociada a este número. Registrate en #{ENV.fetch('APP_HOST', 'la app')}."
    audit.mark_denied!(error_message: "unknown_user")
    WhatsappBot::Sender.deliver(inbound.from, message)
  end

  def dispatch_for_user(user, inbound, audit)
    session = WhatsappBot::Session.new(user)
    resolution = WhatsappBot::BusinessResolver.call(
      user,
      session_business_id: session.get&.dig(:business_id)
    )

    unless resolution.ok?
      message = denial_message(resolution.error)
      audit.mark_denied!(error_message: resolution.error.to_s)
      WhatsappBot::Sender.deliver(inbound.from, message)
      return
    end

    WhatsappBot::AuthorizationGateway.authorize!(user: user, business: resolution.business)
    WhatsappBot::DispatchService.call(
      user,
      inbound.body,
      business: resolution.business,
      audit: audit
    )
  rescue WhatsappBot::AuthorizationGateway::NotAuthorized => e
    audit.mark_denied!(error_message: e.message, business: resolution&.business)
    WhatsappBot::Sender.deliver(
      inbound.from,
      "No tenés permiso para operar esta tienda por WhatsApp."
    )
  end

  def denial_message(error)
    case error
    when :not_authorized
      "Tu cuenta no tiene una tienda autorizada para WhatsApp. Pedile a un admin que la habilite."
    when :ambiguous
      "Tenés varias tiendas habilitadas. Configurá tu tienda default de WhatsApp en la app o pedile a un admin que deje una sola habilitada."
    else
      "No pude resolver la tienda para este mensaje."
    end
  end
end
