require "test_helper"

class ApplicationServiceTest < ActiveSupport::TestCase
  test "class call instantiates the service and delegates to instance call" do
    service_class = Class.new(ApplicationService) do
      def initialize(value, suffix:)
        @value = value
        @suffix = suffix
      end

      def call
        "#{@value}-#{@suffix}"
      end
    end

    assert_equal "hermes-service", service_class.call("hermes", suffix: "service")
  end

  test "raises when subclass does not implement call" do
    service_class = Class.new(ApplicationService)

    error = assert_raises(NotImplementedError) { service_class.call }
    assert_match "must implement #call", error.message
  end
end
