require "rails_helper"

RSpec.describe "Gestor de vacaciones" do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:hr) { create(:employee, company: company, role: "hr") }

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
end
