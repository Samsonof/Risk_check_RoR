class Operator < ApplicationRecord
  ROLES = %w[operator superadmin].freeze
  validates :role, inclusion: { in: ROLES }

  has_many :operator_decisions, dependent: :nullify

  def superadmin? = role == "superadmin"
  def role_label
    superadmin? ? "Superadmin" : "Operator"
  end
end
