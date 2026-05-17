require "json"
require "net/http"
require "uri"

class RiskEngineClient
  ENDPOINT = ENV.fetch("RISK_ENGINE_URL", "http://127.0.0.1:5055/score")

  def self.score(risk_case)
    uri = URI(ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = risk_case.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 0.4, read_timeout: 0.8) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  rescue StandardError
    fallback_score(risk_case)
  end

  def self.fallback_score(risk_case)
    score = 28 + risk_case[:triggers].size * 10
    score += 12 unless risk_case[:kyc_level_2]
    score += 10 if risk_case[:deposits_before_kyc_l1]
    score += 8 if risk_case[:kyc_l1_hours_before_withdrawal] < 36
    score = [score, 96].min

    {
      "risk_score" => score,
      "decision" => score >= 85 ? "block" : "review",
      "engine_status" => "rails_fallback",
      "checked_at" => Time.now.strftime("%H:%M:%S"),
      "reasons" => risk_case[:triggers]
    }
  end
end
