module Vacations
  # R4: requested periods become taken when their start date arrives.
  # (The period status does not affect the balance: days were deducted on approval.)
  class MarkTaken
    def self.call(as_of: Date.current)
      LeavePeriod.where(status: "requested").where("start_date <= ?", as_of)
                 .update_all(status: "taken", updated_at: Time.current)
    end
  end
end
