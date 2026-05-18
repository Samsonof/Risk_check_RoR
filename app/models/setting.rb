class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :kind, inclusion: { in: %w[number boolean] }

  scope :tunables,  -> { where(category: %w[limit scoring kyc]).order(:category, :key) }
  scope :toggles,   -> { where(category: "toggle").order(:key) }

  def parsed_value
    kind == "boolean" ? %w[true 1 yes on].include?(value.to_s.downcase) : value.to_f
  end

  class << self
    def get(key, fallback = nil)
      row = find_by(key: key)
      row ? row.parsed_value : fallback
    end

    def set!(key, value)
      row = find_by!(key: key)
      row.update!(value: value.to_s)
      row
    end
  end
end
