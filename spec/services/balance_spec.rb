require "rails_helper"

RSpec.describe Vacations::Balance do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:employee) { create(:employee, company: company) }
  let!(:legal) { grant!(employee, types[:legal], 15, on: Date.new(2025, 3, 2)) }

  before { grant!(employee, types[:administrative], 3, on: Date.new(2026, 1, 2)) }

  def balance(on) = described_class.new(employee, as_of: on)

  it "suma solo los movimientos con fecha efectiva hasta la fecha consultada (R1)" do
    expect(balance(Date.new(2025, 12, 31)).available("vacation")).to eq(15)
    expect(balance(Date.new(2025, 12, 31)).available("administrative")).to eq(0)
    expect(balance(Date.new(2026, 1, 2)).available_by_pool).to eq("vacation" => 15, "administrative" => 3)
  end

  it "muestra el vencimiento recién desde su fecha efectiva" do
    Ledger::Expire.call(grant: legal)
    expect(balance(Date.new(2027, 3, 1)).available("vacation")).to eq(15)

    expired = balance(Date.new(2027, 3, 2))
    expect(expired.cell(types[:legal], :accrued)).to eq(15)
    expect(expired.cell(types[:legal], :expired)).to eq(-15)
    expect(expired.available("vacation")).to eq(0)
  end
end
