class Decision < ApplicationRecord
  belongs_to :withdrawal_request
  OUTCOMES = %w[auto_approve review].freeze
  validates :outcome, inclusion: { in: OUTCOMES }

  def reasons
    JSON.parse(reasons_json || "[]")
  rescue JSON::ParserError
    []
  end

  def block_results
    JSON.parse(block_results_json || "{}")
  rescue JSON::ParserError
    {}
  end
end
