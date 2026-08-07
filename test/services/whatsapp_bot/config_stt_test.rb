require "test_helper"

class WhatsappBot::ConfigSttTest < ActiveSupport::TestCase
  test "groq preset resolves base url, model and api key env" do
    WhatsappBot::Config.with_settings(
      "media" => {
        "stt" => { "provider" => "groq" }
      }
    ) do
      assert_equal :groq, WhatsappBot::Config.media_stt_provider
      assert_equal "https://api.groq.com/openai/v1", WhatsappBot::Config.media_stt_base_url
      assert_equal "GROQ_API_KEY", WhatsappBot::Config.media_stt_api_key_env
      assert_equal "whisper-large-v3-turbo", WhatsappBot::Config.media_stt_model
    end
  end

  test "stt overrides win over presets" do
    WhatsappBot::Config.with_settings(
      "media" => {
        "stt" => {
          "provider" => "groq",
          "model" => "whisper-large-v3",
          "base_url" => "https://example.test/v1",
          "api_key_env" => "CUSTOM_STT_KEY"
        }
      }
    ) do
      assert_equal "whisper-large-v3", WhatsappBot::Config.media_stt_model
      assert_equal "https://example.test/v1", WhatsappBot::Config.media_stt_base_url
      assert_equal "CUSTOM_STT_KEY", WhatsappBot::Config.media_stt_api_key_env
    end
  end

  test "vision does not fall back to text agent model" do
    WhatsappBot::Config.with_settings(
      "agent" => { "llm_provider" => "groq", "model" => "openai/gpt-oss-20b" },
      "media" => {
        "vision" => { "provider" => "openai" }
      }
    ) do
      assert_equal :openai, WhatsappBot::Config.media_vision
      assert_equal "gpt-4o-mini", WhatsappBot::Config.media_vision_model
      assert_equal "OPENAI_API_KEY", WhatsappBot::Config.media_vision_api_key_env
      assert_equal :json_schema, WhatsappBot::Config.media_vision_response_format
    end
  end

  test "legacy transcriber key still selects fake" do
    WhatsappBot::Config.with_settings(
      "media" => {
        "transcriber" => "fake",
        "whisper_model" => "whisper-1"
      }
    ) do
      assert_equal :fake, WhatsappBot::Config.media_transcriber
      assert_equal "whisper-1", WhatsappBot::Config.media_whisper_model
    end
  end

  test "groq llm preset resolves chat base url and api key env" do
    WhatsappBot::Config.with_settings(
      "agent" => {
        "llm_provider" => "groq"
      }
    ) do
      assert_equal :groq, WhatsappBot::Config.agent_llm_provider
      assert_equal "https://api.groq.com/openai/v1", WhatsappBot::Config.agent_llm_base_url
      assert_equal "GROQ_API_KEY", WhatsappBot::Config.agent_llm_api_key_env
      assert_equal "openai/gpt-oss-20b", WhatsappBot::Config.agent_model
      assert_equal :json_schema, WhatsappBot::Config.agent_llm_response_format
    end
  end
end
