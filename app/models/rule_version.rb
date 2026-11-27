class RuleVersion < ApplicationRecord
  validates :rule_key, :strategy, :effective_from, presence: true
end
