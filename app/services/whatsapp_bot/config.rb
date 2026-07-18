module WhatsappBot
  module Config
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

      private

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
