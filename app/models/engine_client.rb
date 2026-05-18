require "json"
require "net/http"
require "uri"

class EngineClient
  ENDPOINT = ENV.fetch("RISK_ENGINE_URL", "http://127.0.0.1:5055")

  class << self
    def evaluate(withdrawal_request)
      call_json(:post, "/evaluate", { withdrawal_request_id: withdrawal_request.id })
    rescue StandardError => e
      Rails.logger.warn("[EngineClient] #{e.class}: #{e.message}")
      { "outcome" => "review", "priority" => "P7", "score_pts" => 0, "engine_status" => "offline",
        "reasons" => [{ "block" => 0, "code" => "engine_offline", "message" => "Engine unreachable; defaulting to review", "pts" => 0 }],
        "block_results" => {} }
    end

    def health
      call_json(:get, "/health")
    rescue StandardError
      { "status" => "offline" }
    end

    private

    def call_json(verb, path, payload = nil)
      uri = URI.join(ENDPOINT, path)
      req = verb == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      if verb == :post
        req["Content-Type"] = "application/json"
        req.body = payload.to_json
      end
      res = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 0.5, read_timeout: 2.0) { |h| h.request(req) }
      JSON.parse(res.body)
    end
  end
end
