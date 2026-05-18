class CasesController < ApplicationController
  before_action :set_wr

  def show
    if @wr.decisions.none?
      EngineClient.evaluate(@wr)
      @wr.reload
    end
    @decision = @wr.latest_decision
  end

  def evaluate
    EngineClient.evaluate(@wr)
    redirect_to case_path(@wr), notice: "Re-evaluated by engine"
  end

  def decide
    action = params[:choice].to_s == "reject" ? "rejected" : "approved"
    apply_operator_decision(action, params[:comment])
  end

  private

  def apply_operator_decision(action, comment)
    return redirect_to(case_path(@wr), alert: "No operator selected") unless current_operator
    return redirect_to(case_path(@wr), alert: "Comment is required") if comment.to_s.strip.empty?

    if @wr.operator_decision.present?
      flash[:alert] = "Already decided by #{@wr.operator_decision.operator.name}"
    else
      OperatorDecision.create!(
        withdrawal_request: @wr,
        operator: current_operator,
        action: action,
        comment: comment.strip,
        acted_at: Time.zone.now
      )
      flash[:notice] = "#{action.capitalize} by #{current_operator.name}"
    end
    redirect_to root_path
  end

  def set_wr
    @wr = WithdrawalRequest.includes(:client, :decisions).find(params[:id])
  end
end
