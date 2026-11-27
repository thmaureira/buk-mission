module LedgerHelpers
  def setup_types(company)
    {
      legal: create(:leave_type, :legal, company: company),
      progressive: create(:leave_type, :progressive, company: company),
      administrative: create(:leave_type, :administrative, company: company)
    }
  end

  def grant!(employee, type, days, on:, key: SecureRandom.uuid)
    Ledger::Grant.call(employee: employee, leave_type: type, days: days, granted_on: on,
                       idempotency_key: key, reason: "test", source: "spec")
  end

  # Invariante central: cada lote cuadra con su libro y el saldo nunca es negativo.
  def expect_ledger_consistent(employee)
    employee.leave_grants.reload.each do |grant|
      expect(grant.ledger_entries.sum(:days)).to eq(grant.remaining_days), "lote #{grant.id} no cuadra"
      expect(grant.remaining_days).to be >= 0
    end
  end
end

RSpec.configure do |config|
  config.include LedgerHelpers
end
