class ConfigsController < ApplicationController
  before_action :require_admin_or_compliance

  def show
    @tunables = Setting.tunables
    @toggles  = Setting.toggles
    @threshold = Setting.find_by(key: "scoring_threshold_pts")
    @country_profiles = CountryProfile.order(:code)
  end

  def update
    (params[:settings] || {}).each do |key, value|
      row = Setting.find_by(key: key)
      next unless row
      row.update!(value: value.to_s)
    end
    EngineClient.send(:call_json, :post, "/reseed-decisions") rescue nil
    redirect_to config_path, notice: "Config saved, all withdrawals re-evaluated"
  end

  def reevaluate_all
    res = EngineClient.send(:call_json, :post, "/reseed-decisions") rescue { "summary" => { "error" => "engine offline" } }
    redirect_to config_path, notice: "Re-evaluated: #{res['summary'].to_json}"
  end

  private

  def require_admin_or_compliance
    return if current_operator&.superadmin?
    redirect_to root_path, alert: "Only superadmin can edit config"
  end
end
