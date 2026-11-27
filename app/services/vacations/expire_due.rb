module Vacations
  # R11: vence los lotes cuya fecha de vencimiento ya llegó.
  #  - Administrativos: política fixed_date 12-31.
  #  - Legales/progresivas: política relative 2y → el lote del aniversario N vence en
  #    el aniversario N+2, es decir, cuando se acumularía un tercer período.
  class ExpireDue
    def self.call(as_of: Date.current)
      LeaveGrant.with_remaining.where("expires_on <= ?", as_of).includes(:leave_type).find_each.filter_map do |grant|
        Ledger::Expire.call(grant: grant)
      end
    end
  end
end
