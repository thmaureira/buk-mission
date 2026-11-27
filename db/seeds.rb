# Demo scenario as of 26/11/2026:
#  1. HR migrates the Excel sheet with cutoff 31/12/2025 (diff report + approval).
#  2. The anniversary job grants the 2026 anniversaries (legal + progressive).
#  3. Vacations are approved (past → taken, future → requested), plus a cancellation and an adjustment.
#  4. Grants of configurable types (administrative, performance) and expirations.
if Company.exists?
  puts "Ya hay datos; use bin/rails db:seed:replant para recargar"
  return
end

today = Date.current
ActiveRecord::Base.transaction do
company = Company.create!(name: "Tellin SpA", country: "CL")

# ---------- Types ----------
types = {
  legal: { name: "Legales", pool: "vacation", grant_mode: "rule", expiration_policy: "relative", expiration_value: "2y", system: true, position: 1 },
  progressive: { name: "Progresivas", pool: "vacation", grant_mode: "rule", expiration_policy: "relative", expiration_value: "2y", system: true, position: 2 },
  administrative: { name: "Días Administrativos", pool: "administrative", grant_mode: "manual", expiration_policy: "fixed_date", expiration_value: "12-31", system: true, position: 3 },
  rendimiento: { name: "Días por rendimiento", pool: "rendimiento", grant_mode: "manual", expiration_policy: "relative", expiration_value: "6m", position: 10 }
}.to_h { |code, attrs| [code, company.leave_types.create!(attrs.merge(code: code.to_s))] }

# ---------- Versioned rules ----------
%w[legal_days progressive_days proportional_days].each do |key|
  RuleVersion.create!(country: "CL", rule_key: key, strategy: VacationRules::Registry::DEFAULTS[key],
                      effective_from: Date.new(2000, 1, 1), notes: "Código del Trabajo, arts. 67, 68 y 73")
end

# ---------- National holidays (approx.) ----------
{
  2025 => %w[01-01 04-18 04-19 05-01 05-21 06-20 06-29 07-16 08-15 09-18 09-19 10-12 10-31 11-01 12-08 12-25],
  2026 => %w[01-01 04-03 04-04 05-01 05-21 06-21 06-29 07-16 08-15 09-18 09-19 10-12 10-31 11-01 12-08 12-25],
  2027 => %w[01-01 03-26 03-27 05-01 05-21 06-21 06-28 07-16 08-15 09-17 09-18 09-19 10-11 10-31 11-01 12-08 12-25]
}.each do |year, dates|
  names = ["Año Nuevo", "Viernes Santo", "Sábado Santo", "Día del Trabajo", "Glorias Navales", "Pueblos Indígenas",
           "San Pedro y San Pablo", "Virgen del Carmen", "Asunción de la Virgen", "Independencia Nacional",
           "Glorias del Ejército", "Encuentro de Dos Mundos", "Iglesias Evangélicas", "Todos los Santos",
           "Inmaculada Concepción", "Navidad"]
  names.insert(9, "Feriado adicional Fiestas Patrias") if dates.size == 17
  dates.each_with_index { |d, i| Holiday.create!(date: Date.parse("#{year}-#{d}"), name: names[i]) }
end

# ---------- Employees ----------
emp = ->(attrs) { company.employees.create!(attrs) }
ana = emp.(first_name: "Ana", last_name: "Rojas", rut: "12.345.678-5", role: "hr", area: "Personas", job_title: "Jefa de Personas", hire_date: Date.new(2018, 3, 1))
pedro = emp.(first_name: "Pedro", last_name: "Soto", rut: "9.876.543-2", role: "manager", area: "Operaciones", job_title: "Gerente de Operaciones", hire_date: Date.new(2012, 5, 14), prior_service_months: 126, prior_service_document_ref: "Certificado AFP #4411")
javier = emp.(first_name: "Javier", last_name: "Contreras", rut: "15.246.813-7", role: "manager", area: "Tecnología", job_title: "Líder de Tecnología", hire_date: Date.new(2019, 7, 1), prior_service_months: 38, prior_service_document_ref: "Certificado AFP #5120")
camila = emp.(first_name: "Camila", last_name: "Fuentes", rut: "17.654.321-K", area: "Operaciones", job_title: "Analista de Operaciones", hire_date: Date.new(2021, 12, 1), manager: pedro)
diego = emp.(first_name: "Diego", last_name: "Muñoz", rut: "13.579.246-8", area: "Operaciones", job_title: "Supervisor de Turno", hire_date: Date.new(2015, 11, 26), prior_service_months: 64, prior_service_document_ref: "Certificado AFP #3982", manager: pedro)
matias = emp.(first_name: "Matías", last_name: "Herrera", rut: "10.111.222-3", area: "Comercial", job_title: "Ejecutivo Comercial", hire_date: Date.new(2017, 8, 21), prior_service_months: 132, prior_service_document_ref: "Certificado AFP #2207", manager: pedro)
francisca = emp.(first_name: "Francisca", last_name: "Lagos", rut: "19.283.746-1", area: "Tecnología", job_title: "Diseñadora UX", hire_date: Date.new(2023, 1, 9), manager: javier)
valentina = emp.(first_name: "Valentina", last_name: "Pérez", rut: "20.111.333-9", area: "Tecnología", job_title: "Desarrolladora", hire_date: Date.new(2026, 3, 2), manager: javier)

# ---------- 1. Migration from Excel (R6) ----------
cutoff = Date.new(2025, 12, 31)
import = OpeningBalances::Parse.call(
  company: company, uploaded_by: ana, cutoff_on: cutoff, filename: "saldo_inicial_2025.csv",
  content: Rails.root.join("db/seeds/saldo_inicial_2025.csv").read
)
OpeningBalances::Approve.call(import: import, actor: ana)
import.update_columns(created_at: Time.zone.local(2026, 1, 2, 10), approved_at: Time.zone.local(2026, 1, 2, 16))

# A second sheet with errors, pending review (to show the diff report).
OpeningBalances::Parse.call(
  company: company, uploaded_by: ana, cutoff_on: cutoff, filename: "saldo_inicial_correccion.csv",
  content: Rails.root.join("db/seeds/saldo_inicial_correccion.csv").read
)

# ---------- 2. 2026 anniversaries (R2, R3) ----------
company.employees.each { |e| Vacations::AnniversaryGrants.call(employee: e, as_of: today) }

# ---------- 4a. Configurable grants (R10) ----------
Vacations::BulkGrant.call(
  leave_type: types[:administrative], employees: company.employees.where("hire_date <= ?", Date.new(2026, 1, 2)).to_a,
  days: 3, granted_on: Date.new(2026, 1, 2), actor: ana, target_description: "Todos los colaboradores",
  reason: "Días administrativos 2026 según reglamento interno"
)
Vacations::BulkGrant.call(
  leave_type: types[:rendimiento], employees: [francisca, javier], days: 2, granted_on: Date.new(2026, 4, 15),
  actor: ana, target_description: "Área: Tecnología (evaluación Q1)", reason: "Bono por rendimiento evaluación Q1 2026"
)

# ---------- 3. Approved vacations (R4) ----------
approve = ->(employee, from, to, approved_on, approver: employee.manager || ana, pool: "vacation") do
  Vacations::ApproveRequest.call(employee: employee, start_date: Date.parse(from), end_date: Date.parse(to),
                                 approver: approver, approved_on: Date.parse(approved_on), pool: pool)
end
approve.(pedro, "2026-01-05", "2026-01-16", "2026-01-02")
approve.(ana, "2026-10-05", "2026-10-09", "2026-09-10", approver: pedro)
approve.(camila, "2026-02-09", "2026-02-20", "2026-01-20")
cancelled = approve.(camila, "2026-04-06", "2026-04-08", "2026-03-20")
Vacations::CancelRequest.call(leave_period: cancelled, actor: ana, reason: "Se cruzó con licencia médica")
approve.(camila, "2026-12-21", "2026-12-30", "2026-11-10")
approve.(camila, "2026-07-20", "2026-07-20", "2026-07-01", pool: "administrative")
approve.(diego, "2026-07-13", "2026-07-24", "2026-06-30")
approve.(javier, "2026-03-16", "2026-03-20", "2026-02-25", approver: ana)
approve.(francisca, "2026-09-21", "2026-09-25", "2026-09-01")
approve.(francisca, "2026-05-08", "2026-05-08", "2026-05-04", pool: "rendimiento")
approve.(matias, "2027-01-04", "2027-01-15", "2026-11-20")
approve.(matias, "2026-06-01", "2026-06-05", "2026-05-15")

# ---------- Manual adjustment (R9) ----------
Vacations::Adjust.call(employee: diego, leave_type: types[:legal], days: 1, actor: ana, token: "seed-diego-1",
                       reason: "Corrección: día descontado dos veces en planilla 2025 (comprobante #881)")

# ---------- 4b. Daily jobs (R4, R11) ----------
Vacations::MarkTaken.call(as_of: today)
Vacations::ExpireDue.call(as_of: today)

end

puts "Seed OK: #{Employee.count} colaboradores, #{LeaveGrant.count} lotes, #{LedgerEntry.count} movimientos"
