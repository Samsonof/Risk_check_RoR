class Deposit < ApplicationRecord
  belongs_to :client
  METHODS = %w[card bank crypto binance].freeze
  validates :method, inclusion: { in: METHODS }
end
