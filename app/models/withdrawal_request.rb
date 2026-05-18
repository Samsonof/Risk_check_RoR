class WithdrawalRequest < ApplicationRecord
  METHODS = %w[bank crypto binance].freeze

  belongs_to :client
  has_many :decisions, -> { order(decided_at: :desc) }, dependent: :destroy
  has_one  :operator_decision, dependent: :destroy

  validates :method, inclusion: { in: METHODS }

  def latest_decision = decisions.first
  def in_queue? = latest_decision&.outcome == "review" && operator_decision.nil?
  def auto_approved? = latest_decision&.outcome == "auto_approve"
  def resolved? = operator_decision.present?

  def time_in_queue_hours
    return 0 unless in_queue?
    base = latest_decision.decided_at
    base = Time.zone.parse(base) if base.is_a?(String)
    ((Time.zone.now - base) / 3600.0).round(1)
  end

  def channel_icon
    { "bank" => "🏦", "crypto" => "₿", "binance" => "🪙" }[method] || "•"
  end
end
