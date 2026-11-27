class AnniversaryGrantsJob < ApplicationJob
  queue_as :default

  def perform(as_of = Date.current.iso8601)
    date = Date.parse(as_of)
    Employee.active.find_each { |employee| Vacations::AnniversaryGrants.call(employee: employee, as_of: date) }
  end
end
