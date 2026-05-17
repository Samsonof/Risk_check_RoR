class DashboardController < ApplicationController
  before_action :load_cases

  def index
    @selected = RiskCaseStore.find(params[:case_id]) || @cases.first
    @score = RiskEngineClient.score(@selected)
  end

  def case_panel
    @selected = RiskCaseStore.find(params[:id])
    @score = RiskEngineClient.score(@selected)
  end

  def score
    risk_case = RiskCaseStore.find(params[:id])
    render json: RiskEngineClient.score(risk_case)
  end

  private

  def load_cases
    @cases = RiskCaseStore.all
  end
end
