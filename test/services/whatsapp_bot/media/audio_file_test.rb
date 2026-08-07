require "test_helper"

class WhatsappBot::Media::AudioFileTest < ActiveSupport::TestCase
  test "maps whatsapp ogg opus mime with codecs to .ogg" do
    assert_equal ".ogg", WhatsappBot::Media::AudioFile.extension_for("audio/ogg; codecs=opus")
    assert_equal "audio/ogg", WhatsappBot::Media::AudioFile.base_mime("audio/ogg; codecs=opus")
  end

  test "upload identity rewrites .bin paths to ogg for opus notes" do
    filename, content_type = WhatsappBot::Media::AudioFile.upload_identity(
      "/tmp/whatsapp-media.bin",
      mime_type: "audio/ogg; codecs=opus"
    )

    assert_equal "whatsapp-audio.ogg", filename
    assert_equal "audio/ogg", content_type
  end
end
