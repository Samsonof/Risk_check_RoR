class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_operator, :all_operators

  private

  def current_operator
    @current_operator ||= Operator.find_by(id: session[:operator_id]) || Operator.where(role: "operator").first
  end

  def all_operators
    @all_operators ||= Operator.order(Arel.sql("CASE role WHEN 'operator' THEN 1 ELSE 2 END"), :name)
  end
end
