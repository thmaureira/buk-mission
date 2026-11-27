module OpeningBalances
  # R6 (paso 2): RRHH aprueba el reporte y se crean los movimientos de apertura.
  # Cada lote apunta a la fila exacta del Excel de la que salió (source).
  class Approve
    COLUMNS = { legal_days: "legal", progressive_days: "progressive", administrative_days: "administrative" }.freeze

    def self.call(**) = new(**).call

    def initialize(import:, actor:)
      @import = import
      @actor = actor
    end

    def call
      raise Ledger::Error, "La migración ya fue procesada" unless @import.pending?
      raise Ledger::Error, "No hay filas válidas para importar" if @import.importable_rows.empty?

      types = @import.company.leave_types.where(code: COLUMNS.values).index_by(&:code)
      ActiveRecord::Base.transaction do
        @import.importable_rows.each { |row| import_row(row, types) }
        @import.update!(status: "approved", approved_by: @actor, approved_at: Time.current)
      end
      @import
    end

    private

    def import_row(row, types)
      employee = row.employee
      cutoff = @import.cutoff_on
      COLUMNS.each do |column, code|
        days = row.public_send(column)
        next unless days.positive?

        type = types.fetch(code)
        Ledger::Grant.call(
          employee: employee, leave_type: type, days: days, granted_on: cutoff,
          period: "Saldo inicial", actor: @actor,
          expires_on: expiration(type, employee, cutoff),
          reason: "Saldo inicial migrado desde Excel (aprobado por #{@actor.name})",
          source: "excel:#{@import.filename}#fila #{row.row_number}",
          idempotency_key: "opening:import:#{@import.id}:row:#{row.row_number}:#{code}"
        )
      end
      employee.update!(ledger_opened_on: cutoff)
    end

    # Supuesto: el saldo legal de apertura se trata como períodos ya acumulados y
    # vence un año después del próximo aniversario (cuando entraría un tercer período).
    def expiration(type, employee, cutoff)
      return type.expiration_for(cutoff) unless type.pool == "vacation"

      next_anniversary = employee.anniversaries_between(cutoff + 1, cutoff.next_year(1)).first&.last
      (next_anniversary || cutoff.next_year).next_year
    end
  end
end
