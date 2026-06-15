class RoleAssignment < ApplicationRecord
  ROLES = %w[owner manager operator viewer].freeze

  belongs_to :user
  belongs_to :business

  validates :role, inclusion: { in: ROLES }
end
