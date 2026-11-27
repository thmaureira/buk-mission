class MarkTakenJob < ApplicationJob
  queue_as :default

  def perform(as_of = Date.current.iso8601)
    Vacations::MarkTaken.call(as_of: Date.parse(as_of))
  end
end
