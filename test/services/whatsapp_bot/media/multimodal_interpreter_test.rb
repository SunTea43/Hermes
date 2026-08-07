require "test_helper"

class WhatsappBot::Media::MultimodalInterpreterTest < ActiveSupport::TestCase
  test "fake vision client returns purchase interpretation" do
    tempfile = Tempfile.new([ "nota", ".jpg" ])
    tempfile.write("fake-image")
    tempfile.rewind

    interpretation = WhatsappBot::Media::MultimodalInterpreter.call(
      file_path: tempfile.path,
      mime_type: "image/jpeg",
      caption: "compra",
      catalog_names: [ "Arroz" ],
      client: WhatsappBot::Media::FakeVisionClient.new
    )

    assert_equal :purchase, interpretation.intent
    assert_equal "Juanito", interpretation.entities[:supplier_name]
    assert_equal "arroz", interpretation.entities[:items].first["product_name"]
  ensure
    tempfile.close!
  end
end
