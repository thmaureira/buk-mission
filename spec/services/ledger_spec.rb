require "rails_helper"

RSpec.describe "Libro de vacaciones" do
  let(:company) { create(:company) }
  let!(:types) { setup_types(company) }
  let(:employee) { create(:employee, company: company) }
  let(:hr) { create(:employee, company: company, role: "hr") }

  describe Ledger::Grant do
    it "es idempotente por clave" do
      2.times { grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2), key: "k1") }
      expect(employee.leave_grants.count).to eq(1)
      expect(LedgerEntry.count).to eq(1)
    end

    it "aplica el vencimiento del tipo" do
      grant = grant!(employee, types[:administrative], 3, on: Date.new(2026, 1, 2))
      expect(grant.expires_on).to eq(Date.new(2026, 12, 31))
    end
  end

  describe Ledger::Consume do
    it "descuenta primero del lote que vence antes (FEFO)" do
      old = grant!(employee, types[:legal], 5, on: Date.new(2025, 3, 2))
      new = grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2))
      Ledger::Consume.call(employee: employee, lots: employee.leave_grants, days: 7, on: Date.new(2026, 4, 1),
                           idempotency_prefix: "u1", reason: "t", source: "spec")
      expect(old.reload.remaining_days).to eq(0)
      expect(new.reload.remaining_days).to eq(13)
      expect_ledger_consistent(employee)
    end

    it "no permite saldo negativo" do
      grant!(employee, types[:legal], 5, on: Date.new(2026, 3, 2))
      expect do
        Ledger::Consume.call(employee: employee, lots: employee.leave_grants, days: 6, on: Date.new(2026, 4, 1),
                             idempotency_prefix: "u1", reason: "t", source: "spec")
      end.to raise_error(Ledger::InsufficientBalance)
      expect(LedgerEntry.where(kind: "usage")).to be_empty
    end

    it "no usa lotes vencidos" do
      grant!(employee, types[:administrative], 3, on: Date.new(2025, 1, 2)) # vence 31/12/2025
      expect do
        Ledger::Consume.call(employee: employee, lots: employee.leave_grants, days: 1, on: Date.new(2026, 1, 5),
                             idempotency_prefix: "u1", reason: "t", source: "spec")
      end.to raise_error(Ledger::InsufficientBalance)
    end
  end

  describe Ledger::Reverse do
    it "agrega un movimiento opuesto en vez de borrar" do
      grant = grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2))
      entry = grant.ledger_entries.first
      Ledger::Reverse.call(entry: entry, actor: hr, reason: "Carga duplicada")
      expect(grant.reload.remaining_days).to eq(0)
      expect(LedgerEntry.count).to eq(2)
      expect { Ledger::Reverse.call(entry: entry, actor: hr, reason: "otra vez") }.to raise_error(Ledger::NotReversible)
      expect_ledger_consistent(employee)
    end

    it "no revierte una carga cuyos días ya se usaron" do
      grant = grant!(employee, types[:legal], 5, on: Date.new(2026, 3, 2))
      Ledger::Consume.call(employee: employee, lots: employee.leave_grants, days: 2, on: Date.new(2026, 4, 1),
                           idempotency_prefix: "u1", reason: "t", source: "spec")
      expect { Ledger::Reverse.call(entry: grant.ledger_entries.find_by(kind: "grant"), actor: hr, reason: "x") }
        .to raise_error(Ledger::NotReversible)
    end
  end

  describe "solo inserción (R9)" do
    let!(:entry) { grant!(employee, types[:legal], 15, on: Date.new(2026, 3, 2)).ledger_entries.first }

    it "el modelo no permite editar ni borrar" do
      expect { entry.update!(days: 20) }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { entry.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "la base de datos rechaza UPDATE directo" do
      expect { LedgerEntry.where(id: entry.id).update_all(days: 20) }.to raise_error(ActiveRecord::StatementInvalid, /solo inserción/)
    end

    it "la base de datos rechaza DELETE directo" do
      expect { LedgerEntry.where(id: entry.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid, /solo inserción/)
    end
  end
end
