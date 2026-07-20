require "test_helper"

class WhatsappBot::Skills::RegistryTest < ActiveSupport::TestCase
  test "lists registered skills" do
    assert_includes WhatsappBot::Skills::Registry.names, "registrar_venta"
    assert_includes WhatsappBot::Skills::Registry.names, "consultar_inventario"
  end

  test "raises for unknown skill" do
    assert_raises WhatsappBot::Skills::Registry::UnknownSkillError do
      WhatsappBot::Skills::Registry.fetch("no_existe")
    end
  end
end
