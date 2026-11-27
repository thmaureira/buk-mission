module Vacations
  # R11: expires the lots whose expiration date has arrived.
  #  - Administrative: fixed_date policy 12-31.
  #  - Legal/progressive: relative policy 2y → the lot from anniversary N expires on
  #    anniversary N+2, i.e. when a third period would accumulate.
  class ExpireDue
    def self.call(as_of: Date.current)
      LeaveGrant.with_remaining.where("expires_on <= ?", as_of).includes(:leave_type).find_each.filter_map do |grant|
        Ledger::Expire.call(grant: grant)
      end
    end
  end
end
