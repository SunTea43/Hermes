namespace :eval do
  desc "Run WhatsApp interpreter evals against the golden dataset"
  task run: :environment do
    client = if ENV["EVAL_FAKE"] == "1"
      responses = {}
      Dir[Rails.root.join("test/evals/cases/*.yml")].each do |path|
        YAML.safe_load_file(path).each do |row|
          expected = row.fetch("expected")
          responses[row.fetch("message")] = {
            "intent" => expected.fetch("intent"),
            "entities" => expected["entities"] || {},
            "confidence" => 0.95
          }
        end
      end
      WhatsappBot::Llm::FakeClient.new(responses)
    end

    scorecard = WhatsappBot::Evals::Runner.call(client: client)
    abort("Eval thresholds failed") unless scorecard.passed
  end
end
