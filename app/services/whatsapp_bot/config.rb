module WhatsappBot
  module Config
    # Presets for OpenAI-compatible speech-to-text providers.
    # Override any field under media.stt in config/whatsapp.yml.
    STT_PROVIDER_PRESETS = {
      "openai" => {
        "base_url" => "https://api.openai.com/v1",
        "api_key_env" => "OPENAI_API_KEY",
        "model" => "whisper-1"
      },
      "groq" => {
        "base_url" => "https://api.groq.com/openai/v1",
        "api_key_env" => "GROQ_API_KEY",
        "model" => "whisper-large-v3-turbo"
      }
    }.freeze

    # Presets for OpenAI-compatible chat/completions (Interpreter LLM).
    # Groq json_schema only works on specific models (e.g. openai/gpt-oss-*).
    LLM_PROVIDER_PRESETS = {
      "openai" => {
        "base_url" => "https://api.openai.com/v1",
        "api_key_env" => "OPENAI_API_KEY",
        "model" => "gpt-4o-mini",
        "response_format" => "json_schema"
      },
      "groq" => {
        "base_url" => "https://api.groq.com/openai/v1",
        "api_key_env" => "GROQ_API_KEY",
        "model" => "openai/gpt-oss-20b",
        "response_format" => "json_schema"
      }
    }.freeze

    # Presets for multimodal image interpretation (chat/completions with image_url).
    # Do NOT reuse agent_model: text models (e.g. gpt-oss-20b) are invalid for vision.
    VISION_PROVIDER_PRESETS = {
      "openai" => {
        "base_url" => "https://api.openai.com/v1",
        "api_key_env" => "OPENAI_API_KEY",
        "model" => "gpt-4o-mini",
        "response_format" => "json_schema"
      },
      # Only if your Groq account exposes a vision model (many free tiers do not).
      "groq" => {
        "base_url" => "https://api.groq.com/openai/v1",
        "api_key_env" => "GROQ_API_KEY",
        "model" => "meta-llama/llama-4-scout-17b-16e-instruct",
        "response_format" => "json_object"
      },
      # Google AI Studio free tier (OpenAI-compatible endpoint).
      # Prefer *-latest / 3.1 flash-lite: gemini-2.0-flash often has free-tier limit 0 for new keys.
      "gemini" => {
        "base_url" => "https://generativelanguage.googleapis.com/v1beta/openai",
        "api_key_env" => "GEMINI_API_KEY",
        "model" => "gemini-flash-lite-latest",
        "response_format" => "json_object"
      }
    }.freeze

    class << self
      def settings
        @settings ||= load!
      end

      def reload!
        @settings = load!
      end

      # Temporarily merge settings for tests. Prefer this over stubbing module methods.
      def with_settings(overrides)
        previous = settings
        @settings = previous.merge(overrides).with_indifferent_access
        yield
      ensure
        @settings = previous
      end

      def default_provider
        settings.fetch("default_provider").to_sym
      end

      def validate_signatures?
        ActiveModel::Type::Boolean.new.cast(settings.fetch("validate_signatures"))
      end

      def phone_overrides
        settings.fetch("phone_overrides", {}).transform_keys(&:to_s).transform_values(&:to_sym)
      end

      def business_overrides
        settings.fetch("business_overrides", {}).transform_keys(&:to_s).transform_values(&:to_sym)
      end

      def agent_settings
        settings.fetch("agent", {})
      end

      def agent_default
        agent_settings.fetch("default", "regex").to_sym
      end

      # :fake | :openai | :groq | custom with agent.base_url + agent.api_key_env
      def agent_llm_provider
        agent_settings.fetch("llm_provider", "openai").to_sym
      end

      def agent_model
        agent_settings[:model].presence || llm_preset.fetch("model", "gpt-4o-mini")
      end

      def agent_temperature
        agent_settings.fetch("temperature", 0).to_f
      end

      def agent_confidence_threshold
        agent_settings.fetch("confidence_threshold", 0.7).to_f
      end

      def agent_llm_base_url
        agent_settings[:base_url].presence ||
          llm_preset["base_url"].presence ||
          ENV["OPENAI_BASE_URL"].presence ||
          "https://api.openai.com/v1"
      end

      def agent_llm_api_key_env
        (
          agent_settings[:api_key_env].presence ||
          llm_preset["api_key_env"].presence ||
          "OPENAI_API_KEY"
        ).to_s
      end

      def agent_llm_api_key
        ENV[agent_llm_api_key_env].to_s.presence
      end

      # :json_schema (preferred) or :json_object (fallback for models without structured outputs)
      def agent_llm_response_format
        (
          agent_settings[:response_format].presence ||
          llm_preset["response_format"].presence ||
          "json_schema"
        ).to_sym
      end

      def media_settings
        settings.fetch("media", {})
      end

      def media_audio_enabled?
        ActiveModel::Type::Boolean.new.cast(media_settings.fetch("audio_enabled", false))
      end

      def media_image_enabled?
        ActiveModel::Type::Boolean.new.cast(media_settings.fetch("image_enabled", false))
      end

      def media_max_bytes
        media_settings.fetch("max_bytes", 16.megabytes).to_i
      end

      def media_stt_settings
        media_settings.fetch("stt", {})
      end

      # :fake | :openai | :groq | custom name with stt.base_url + stt.api_key_env
      def media_stt_provider
        (
          media_stt_settings[:provider].presence ||
          media_settings[:transcriber].presence || # legacy
          "openai"
        ).to_sym
      end

      # Legacy alias used by Transcriber / older callers.
      def media_transcriber
        media_stt_provider
      end

      def media_stt_model
        media_stt_settings[:model].presence ||
          media_settings[:whisper_model].presence || # legacy
          stt_preset.fetch("model", "whisper-1")
      end

      def media_whisper_model
        media_stt_model
      end

      def media_stt_base_url
        media_stt_settings[:base_url].presence ||
          stt_preset["base_url"].presence ||
          ENV["OPENAI_BASE_URL"].presence ||
          "https://api.openai.com/v1"
      end

      def media_stt_api_key_env
        (
          media_stt_settings[:api_key_env].presence ||
          stt_preset["api_key_env"].presence ||
          "OPENAI_API_KEY"
        ).to_s
      end

      def media_stt_api_key
        ENV[media_stt_api_key_env].to_s.presence
      end

      def media_vision_settings
        raw = media_settings[:vision]
        return raw.with_indifferent_access if raw.is_a?(Hash)

        # Legacy: media.vision: openai + media.vision_model: gpt-4o-mini
        {
          "provider" => raw.presence || "openai",
          "model" => media_settings[:vision_model]
        }.with_indifferent_access
      end

      # :fake | :openai | :groq
      def media_vision
        (media_vision_settings[:provider].presence || "openai").to_sym
      end

      def media_vision_model
        media_vision_settings[:model].presence ||
          vision_preset.fetch("model", "gpt-4o-mini")
      end

      def media_vision_base_url
        media_vision_settings[:base_url].presence ||
          vision_preset["base_url"].presence ||
          "https://api.openai.com/v1"
      end

      def media_vision_api_key_env
        (
          media_vision_settings[:api_key_env].presence ||
          vision_preset["api_key_env"].presence ||
          "OPENAI_API_KEY"
        ).to_s
      end

      def media_vision_api_key
        ENV[media_vision_api_key_env].to_s.presence
      end

      def media_vision_response_format
        (
          media_vision_settings[:response_format].presence ||
          vision_preset["response_format"].presence ||
          "json_schema"
        ).to_sym
      end

      private

      def stt_preset
        STT_PROVIDER_PRESETS.fetch(media_stt_provider.to_s, {})
      end

      def llm_preset
        LLM_PROVIDER_PRESETS.fetch(agent_llm_provider.to_s, {})
      end

      def vision_preset
        VISION_PROVIDER_PRESETS.fetch(media_vision.to_s, {})
      end

      def load!
        path = Rails.root.join("config/whatsapp.yml")
        raw = YAML.safe_load(
          ERB.new(path.read).result,
          aliases: true
        ) || {}

        env_config = raw.fetch(Rails.env, raw["default"] || {})
        env_config.with_indifferent_access
      end
    end
  end
end
