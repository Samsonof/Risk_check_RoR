class OperatorDecision < ApplicationRecord
  belongs_to :withdrawal_request
  belongs_to :operator
  ACTIONS = %w[approved rejected].freeze
  validates :action, inclusion: { in: ACTIONS }
  validates :comment, presence: true
end
