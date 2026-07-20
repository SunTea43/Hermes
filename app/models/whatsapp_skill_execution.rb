class WhatsappSkillExecution < ApplicationRecord
  belongs_to :user
  belongs_to :business

  validates :skill_name, :idempotency_key, :input_hash, presence: true
  validates :idempotency_key, uniqueness: true
end
