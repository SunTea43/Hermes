require "yaml"

module WhatsappBot
  module Evals
    class Runner
      CaseResult = Data.define(
        :id, :category, :intent_match, :entity_match, :consistency, :predicted_intent, :expected_intent
      )

      Scorecard = Data.define(
        :cases, :intent_accuracy, :entity_exact_match, :consistency, :thresholds, :passed
      )

      def self.call(client: nil, cases_dir: Rails.root.join("test/evals/cases"), thresholds_path: Rails.root.join("test/evals/thresholds.yml"))
        new(client: client, cases_dir: cases_dir, thresholds_path: thresholds_path).call
      end

      def initialize(client: nil, cases_dir:, thresholds_path:)
        @client = client
        @cases_dir = Pathname(cases_dir)
        @thresholds = YAML.safe_load_file(thresholds_path).with_indifferent_access
      end

      def call
        results = load_cases.map { |item| evaluate_case(item) }
        intent_accuracy = ratio(results.count(&:intent_match), results.size)
        entity_exact_match = ratio(results.count(&:entity_match), results.size)
        consistency = ratio(results.sum(&:consistency), results.size)

        scorecard = Scorecard.new(
          cases: results,
          intent_accuracy: intent_accuracy,
          entity_exact_match: entity_exact_match,
          consistency: consistency,
          thresholds: @thresholds,
          passed: intent_accuracy >= @thresholds[:intent_accuracy].to_f &&
            entity_exact_match >= @thresholds[:entity_exact_match].to_f &&
            consistency >= @thresholds[:consistency].to_f
        )

        print_scorecard(scorecard)
        scorecard
      end

      private

      def load_cases
        @cases_dir.glob("*.yml").flat_map do |path|
          category = path.basename(".yml").to_s
          YAML.safe_load_file(path).map { |row| row.merge("category" => category).with_indifferent_access }
        end
      end

      def evaluate_case(item)
        runs = @thresholds.fetch(:consistency_runs, 3).to_i
        predictions = Array.new(runs) { Interpreter.call(item[:message], client: @client) }
        intents = predictions.map(&:intent)
        majority = intents.max_by { |intent| intents.count(intent) }
        expected_intent = item.dig(:expected, :intent).to_sym
        expected_entities = (item.dig(:expected, :entities) || {}).with_indifferent_access

        CaseResult.new(
          id: item[:id],
          category: item[:category],
          intent_match: majority == expected_intent,
          entity_match: entities_match?(predictions.first.entities, expected_entities),
          consistency: intents.count(majority).to_f / runs,
          predicted_intent: majority,
          expected_intent: expected_intent
        )
      end

      def entities_match?(actual, expected)
        return true if expected.blank?

        expected.all? do |key, value|
          normalize(actual[key]) == normalize(value)
        end
      end

      def normalize(value)
        case value
        when Numeric then value.to_f
        when String then value.to_s.downcase.strip
        when Array then value.map { |item| normalize(item) }
        when Hash
          value.to_h.transform_keys(&:to_s).transform_values { |item| normalize(item) }
        else value
        end
      end

      def ratio(numerator, denominator)
        return 0.0 if denominator.zero?

        numerator.to_f / denominator
      end

      def print_scorecard(scorecard)
        puts "WhatsApp Interpreter Eval Scorecard"
        puts "- intent_accuracy: #{pct(scorecard.intent_accuracy)} (min #{pct(scorecard.thresholds[:intent_accuracy])})"
        puts "- entity_exact_match: #{pct(scorecard.entity_exact_match)} (min #{pct(scorecard.thresholds[:entity_exact_match])})"
        puts "- consistency: #{pct(scorecard.consistency)} (min #{pct(scorecard.thresholds[:consistency])})"
        puts "- result: #{scorecard.passed ? 'PASS' : 'FAIL'}"
        scorecard.cases.each do |item|
          status = item.intent_match ? "ok" : "miss"
          puts "  [#{status}] #{item.category}/#{item.id}: expected=#{item.expected_intent} got=#{item.predicted_intent} consistency=#{pct(item.consistency)}"
        end
      end

      def pct(value)
        format("%.1f%%", value.to_f * 100)
      end
    end
  end
end
