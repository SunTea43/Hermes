require "digest"

module WhatsappBot
  module Skills
    class Base
      Result = Data.define(:success, :data, :errors, :idempotent_replay) do
        def initialize(success:, data: {}, errors: [], idempotent_replay: false)
          super
        end

        def success?
          success
        end
      end

      def self.skill_name
        name.demodulize.underscore
      end

      def self.call(user:, business:, input:, idempotency_key: nil)
        new(user: user, business: business, input: input, idempotency_key: idempotency_key).call
      end

      def initialize(user:, business:, input:, idempotency_key: nil)
        @user = user
        @business = business
        @input = input.to_h.with_indifferent_access
        @idempotency_key = idempotency_key.presence
      end

      def call
        raise NotImplementedError
      end

      protected

      def with_idempotency
        if @idempotency_key
          existing = WhatsappSkillExecution.find_by(idempotency_key: @idempotency_key)
          if existing
            return Result.new(
              success: true,
              data: existing.result_payload.with_indifferent_access,
              idempotent_replay: true
            )
          end
        end

        result = yield
        return result unless @idempotency_key && result.success?

        store_execution(result)
      end

      def success(data = {})
        Result.new(success: true, data: data)
      end

      def failure(*errors)
        Result.new(success: false, errors: errors.flatten)
      end

      private

      def store_execution(result)
        WhatsappSkillExecution.create!(
          user: @user,
          business: @business,
          skill_name: self.class.skill_name,
          idempotency_key: @idempotency_key,
          input_hash: Digest::SHA256.hexdigest(@input.sort.to_json),
          result_payload: result.data
        )
        result
      rescue ActiveRecord::RecordNotUnique
        existing = WhatsappSkillExecution.find_by!(idempotency_key: @idempotency_key)
        Result.new(
          success: true,
          data: existing.result_payload.with_indifferent_access,
          idempotent_replay: true
        )
      end
    end
  end
end
