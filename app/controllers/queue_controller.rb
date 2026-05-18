class QueueController < ApplicationController
  PRIORITY_ORDER = %w[P1 P2 P3 P4 P5 P6 P7].freeze

  def index
    decided_ids = OperatorDecision.pluck(:withdrawal_request_id)
    @in_queue = WithdrawalRequest
                  .includes(:client, :decisions, :operator_decision)
                  .where.not(id: decided_ids)
                  .select { |wr| wr.latest_decision&.outcome == "review" }
                  .sort_by { |wr| [PRIORITY_ORDER.index(effective_priority(wr)) || 99, -wr.time_in_queue_hours] }
    @resolved_count = OperatorDecision.count
    @auto_approved_count = WithdrawalRequest.joins(:decisions).where(decisions: { outcome: "auto_approve" }).distinct.count
    @engine_health = EngineClient.health
  end

  def auto_approved
    @auto_approved = WithdrawalRequest
                       .includes(:client, :decisions)
                       .all
                       .select { |wr| wr.latest_decision&.outcome == "auto_approve" }
                       .sort_by { |wr| -(wr.latest_decision&.decided_at&.to_i || 0) }
    @engine_health = EngineClient.health
  end

  helper_method :effective_priority

  # Spec: P7 escalates to P6 after a configurable threshold.
  # We approximate: any P7 case with time_in_queue > 24h becomes P6.
  def effective_priority(wr)
    base = wr.latest_decision&.priority
    return "P7" unless base
    if base == "P7" && wr.time_in_queue_hours > 24
      "P6"
    else
      base
    end
  end
end
