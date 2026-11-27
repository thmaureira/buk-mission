module Vacations
  # R4: los períodos solicitados pasan a tomados cuando llega su fecha de inicio.
  # (El estado del período no afecta el saldo: los días ya se descontaron al aprobar.)
  class MarkTaken
    def self.call(as_of: Date.current)
      LeavePeriod.where(status: "requested").where("start_date <= ?", as_of)
                 .update_all(status: "taken", updated_at: Time.current)
    end
  end
end
