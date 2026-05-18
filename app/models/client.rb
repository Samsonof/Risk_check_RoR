class Client < ApplicationRecord
  KYC_TIERS = { 0 => "Tier 0 — not verified", 1 => "Tier 1 — basic", 2 => "Tier 2 — extended" }.freeze

  has_many :trades,               -> { order(closed_at: :desc) }, dependent: :destroy
  has_many :deposits,             -> { order(occurred_at: :desc) }, dependent: :destroy
  has_many :previous_withdrawals, -> { order(occurred_at: :desc) }, dependent: :destroy
  has_many :ip_events,            -> { order(occurred_at: :desc) }, dependent: :destroy
  has_many :account_events,       -> { order(occurred_at: :desc) }, dependent: :destroy
  has_many :withdrawal_requests,  dependent: :destroy

  def kyc_label = KYC_TIERS[kyc_tier]
  def country = CountryProfile.find_by(code: country_code)
  def account_age_days
    ra = registered_at.is_a?(String) ? Time.zone.parse(registered_at) : registered_at
    ((Time.zone.now - ra) / 86_400).floor
  end
end
