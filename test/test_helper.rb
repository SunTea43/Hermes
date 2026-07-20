ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "shoulda-context"
require "devise"
require_relative "support/whatsapp_test_adapter"

if defined?(Rails::TestUnitReporter) && !Rails::TestUnitReporter.method_defined?(:executable)
  class Rails::TestUnitReporter
    def executable
      "bin/rails test"
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      WhatsappBot::Providers::Resolver.register(:test, WhatsappBot::Providers::TestAdapter)
      WhatsappBot::Providers::TestAdapter.reset!
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)
  end
end
