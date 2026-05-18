class PersonasController < ApplicationController
  def create
    op = Operator.find_by(id: params[:operator_id])
    session[:operator_id] = op.id if op
    redirect_back fallback_location: root_path
  end
end
