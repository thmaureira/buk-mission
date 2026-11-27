require "rails_helper"

RSpec.describe "Gestor de vacaciones" do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:hr) { create(:employee, company: company, role: "hr") }

  describe Vacations::AnniversaryGrants do
    let(:employee) { create(:employee, company: company, hire_date: Date.new(2016, 11, 26), prior_service_months: 120) }

    it "carga 15 legales + progresivas en cada aniversario (R2, R3)" do
      Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2026, 11, 26))
      last = employee.leave_grants.where(granted_on: Date.new(2026, 11, 26))
      expect(last.find_by(leave_type: types[:legal]).granted_days).to eq(15)
      # 10 prior years + 10 current → 10 new years → 3 days
      expect(last.find_by(leave_type: types[:progressive]).granted_days).to eq(3)
    end

    it "si corre dos veces no carga doble" do
      2.times { Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2026, 11, 26)) }
      expect(employee.leave_grants.where(leave_type: types[:legal]).count).to eq(10)
    end

    it "si un día no corrió, se pone al día" do
      Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2024, 1, 1))
      Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2026, 12, 15))
      expect(employee.leave_grants.where(leave_type: types[:legal]).pluck(:granted_on).max).to eq(Date.new(2026, 11, 26))
    end

    it "solo carga aniversarios posteriores al saldo migrado" do
      employee.update!(ledger_opened_on: Date.new(2025, 12, 31))
      Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2026, 11, 26))
      expect(employee.leave_grants.where(leave_type: types[:legal]).count).to eq(1)
    end
  end

  describe Vacations::ApproveRequest do
    let(:employee) { create(:employee, company: company) }

    before do
      Holiday.create!(date: Date.new(2026, 12, 25), name: "Navidad")
      grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2))
    end

    it "descuenta solo días hábiles y queda como solicitado (R4)" do
      period = described_class.call(employee: employee, start_date: Date.new(2026, 12, 21), end_date: Date.new(2026, 12, 30),
                                    approver: hr, approved_on: Date.new(2026, 11, 26))
      expect(period.business_days).to eq(7)
      balance = Vacations::Balance.new(employee, as_of: Date.new(2026, 11, 26))
      expect(balance.requested_days).to eq(7)
      expect(balance.available("vacation")).to eq(8)

      later = Vacations::Balance.new(employee, as_of: Date.new(2026, 12, 31))
      expect(later.requested_days).to eq(0)
      expect(later.row_total(:taken)).to eq(-7)
      expect_ledger_consistent(employee)
    end

    it "rechaza períodos superpuestos" do
      described_class.call(employee: employee, start_date: Date.new(2026, 12, 21), end_date: Date.new(2026, 12, 23), approver: hr)
      expect do
        described_class.call(employee: employee, start_date: Date.new(2026, 12, 23), end_date: Date.new(2026, 12, 24), approver: hr)
      end.to raise_error(Ledger::Error, /superpone/)
    end

    it "al anular, los días vuelven a sus lotes" do
      period = described_class.call(employee: employee, start_date: Date.new(2026, 12, 21), end_date: Date.new(2026, 12, 23), approver: hr)
      Vacations::CancelRequest.call(leave_period: period, actor: hr, reason: "Licencia médica")
      expect(Vacations::Balance.new(employee).available("vacation")).to eq(15)
      expect(period.reload.status).to eq("cancelled")
      expect_ledger_consistent(employee)
    end
  end

  describe Vacations::ExpireDue do
    let(:employee) { create(:employee, company: company, hire_date: Date.new(2020, 3, 2)) }

    it "vence administrativos el 31/12 y deja el movimiento (R11)" do
      grant!(employee, types[:administrative], 3, on: Date.new(2026, 1, 2))
      expect(described_class.call(as_of: Date.new(2026, 12, 30))).to be_empty
      described_class.call(as_of: Date.new(2026, 12, 31))
      described_class.call(as_of: Date.new(2027, 1, 1)) # idempotent
      expiration = LedgerEntry.where(kind: "expiration").sole
      expect(expiration.days).to eq(-3)
      expect(Vacations::Balance.new(employee, as_of: Date.new(2027, 1, 1)).row_total(:expired)).to eq(-3)
    end

    it "vence legales al acumularse un tercer período" do
      Vacations::AnniversaryGrants.call(employee: employee, as_of: Date.new(2023, 3, 2)) # 3 lots: 2021, 2022, 2023
      described_class.call(as_of: Date.new(2023, 3, 2))
      balance = Vacations::Balance.new(employee, as_of: Date.new(2023, 3, 2))
      expect(balance.available("vacation")).to eq(30) # at most two periods
      expect(balance.row_total(:expired)).to eq(-15)
    end
  end

  describe Vacations::Settlement do
    it "suma saldo disponible + solicitados no gozados + proporcional (R5)" do
      employee = create(:employee, company: company, hire_date: Date.new(2025, 3, 2))
      grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2))
      Vacations::ApproveRequest.call(employee: employee, start_date: Date.new(2026, 12, 14), end_date: Date.new(2026, 12, 18),
                                     approver: hr, approved_on: Date.new(2026, 11, 1))
      result = described_class.call(employee: employee, termination_on: Date.new(2026, 11, 26))
      expect(result.available).to eq(10)
      expect(result.requested_not_taken).to eq(5)
      expect(result.proportional).to eq(11)
      expect(result.total).to eq(26)
    end
  end
end
