require "test_helper"

class WhatsappBot::Media::PrepareMessageTest < ActiveSupport::TestCase
  setup do
    @adapter = WhatsappBot::Providers::TestAdapter.new
    WhatsappBot::Providers::TestAdapter.reset!
  end

  test "returns body unchanged when there is no media" do
    inbound = WhatsappBot::Messages::InboundMessage.new(
      provider: :test,
      provider_message_id: "SM1",
      from: "+573000000001",
      to: "+15551234567",
      body: "Vendí 10kg arroz"
    )

    result = WhatsappBot::Media::PrepareMessage.call(inbound: inbound, adapter: @adapter)

    assert result.ok?
    assert_equal "Vendí 10kg arroz", result.body
  end

  test "transcribes audio when enabled" do
    inbound = WhatsappBot::Messages::InboundMessage.new(
      provider: :test,
      provider_message_id: "SM2",
      from: "+573000000001",
      to: "+15551234567",
      body: "",
      media: [
        {
          kind: "audio",
          id: "MED1",
          mime_type: "audio/ogg"
        }
      ]
    )
    transcriber = WhatsappBot::Media::FakeTranscriber.new(
      text: "Recibí de Juanito: arroz 50kg a $2000"
    )

    result = WhatsappBot::Media::PrepareMessage.call(
      inbound: inbound,
      adapter: @adapter,
      transcriber: transcriber
    )

    assert result.ok?
    assert_equal "Recibí de Juanito: arroz 50kg a $2000", result.body
    assert_equal "audio", result.metadata["media_kind"]
    assert_equal 1, transcriber.calls.size
  end

  test "interprets image with vision client when enabled" do
    inbound = WhatsappBot::Messages::InboundMessage.new(
      provider: :test,
      provider_message_id: "SM3",
      from: "+573000000001",
      to: "+15551234567",
      body: "",
      media: [
        {
          kind: "image",
          id: "MED2",
          mime_type: "image/jpeg"
        }
      ]
    )
    vision = WhatsappBot::Media::FakeVisionClient.new

    result = WhatsappBot::Media::PrepareMessage.call(
      inbound: inbound,
      adapter: @adapter,
      business: businesses(:one),
      vision_client: vision
    )

    assert result.ok?
    assert_equal :clarify, result.interpretation.intent
    assert_equal "arroz", result.interpretation.entities[:items].first["product_name"]
    assert_equal 1, vision.calls.size
  end

  test "image caption compra resolves purchase intent" do
    inbound = WhatsappBot::Messages::InboundMessage.new(
      provider: :test,
      provider_message_id: "SM3b",
      from: "+573000000001",
      to: "+15551234567",
      body: "",
      media: [
        {
          kind: "image",
          id: "MED2b",
          mime_type: "image/jpeg",
          caption: "compra"
        }
      ]
    )

    result = WhatsappBot::Media::PrepareMessage.call(
      inbound: inbound,
      adapter: @adapter,
      business: businesses(:one),
      vision_client: WhatsappBot::Media::FakeVisionClient.new
    )

    assert result.ok?
    assert_equal :purchase, result.interpretation.intent
  end

  test "falls back to caption when images are disabled" do
    inbound = WhatsappBot::Messages::InboundMessage.new(
      provider: :test,
      provider_message_id: "SM4",
      from: "+573000000001",
      to: "+15551234567",
      body: "",
      media: [
        {
          kind: "image",
          id: "MED3",
          mime_type: "image/jpeg",
          caption: "Recibí de Pedro: arroz 10kg a $2000"
        }
      ]
    )

    WhatsappBot::Config.with_settings(
      WhatsappBot::Config.settings.merge(
        "media" => WhatsappBot::Config.media_settings.merge("image_enabled" => false)
      )
    ) do
      result = WhatsappBot::Media::PrepareMessage.call(inbound: inbound, adapter: @adapter)

      assert result.ok?
      assert_equal "Recibí de Pedro: arroz 10kg a $2000", result.body
      assert_nil result.interpretation
    end
  end
end
