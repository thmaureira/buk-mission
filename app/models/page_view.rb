class PageView < ApplicationRecord
  belongs_to :actor, class_name: "Employee", optional: true

  scope :visits, -> { where(request_method: "GET") }
  scope :actions, -> { where.not(request_method: "GET") }
  scope :since, ->(time) { where(created_at: time..) }
end
