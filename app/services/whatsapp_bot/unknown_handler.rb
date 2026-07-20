module WhatsappBot
  class UnknownHandler < BaseHandler
    def call
      reply(ResponseRenderer.unknown_menu)
    end
  end
end
