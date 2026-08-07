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

  test "fails clearly when image has no caption yet" do
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

    result = WhatsappBot::Media::PrepareMessage.call(inbound: inbound, adapter: @adapter)

    assert result.error?
    assert_equal :image_not_supported, result.error_code
  end

  test "uses image caption while multimodal is disabled" do
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

    result = WhatsappBot::Media::PrepareMessage.call(inbound: inbound, adapter: @adapter)

    assert result.ok?
    assert_equal "Recibí de Pedro: arroz 10kg a $2000", result.body
  end
end
