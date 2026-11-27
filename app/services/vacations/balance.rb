module Vacations
  # R1: el saldo no se guarda, se calcula sumando el libro a una fecha.
  class Balance
    ROWS = [
      [:accrued, "(+) Acumuladas"],
      [:adjustments, "(±) Ajustes"],
      [:taken, "(-) Tomadas"],
      [:expired, "(-) Vencidas"],
      [:future, "(-) Tomadas en el futuro"]
    ].freeze

    attr_reader :employee, :as_of

    def initialize(employee, as_of: Date.current)
      @employee = employee
      @as_of = as_of
    end

    def entries
      @entries ||= LedgerEntry.joins(:leave_grant)
                              .where(leave_grants: { employee_id: employee.id })
                              .where("ledger_entries.effective_on <= ?", as_of)
                              .includes(:leave_period, :actor, reverses_entry: :leave_period,
                                        leave_grant: :leave_type)
                              .chronological.to_a
    end

    def leave_types
      @leave_types ||= entries.map { |e| e.leave_grant.leave_type }.uniq.sort_by { |t| [t.position, t.name] }
    end

    # { leave_type => { bucket => días } }
    def matrix
      @matrix ||= entries.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |entry, acc|
        acc[entry.leave_grant.leave_type][bucket_for(entry)] += entry.days
      end
    end

    def cell(leave_type, bucket) = matrix[leave_type][bucket]
    def row_total(bucket) = leave_types.sum { |t| cell(t, bucket) }
    def type_total(leave_type) = matrix[leave_type].values.sum
    def total = leave_types.sum { |t| type_total(t) }

    def available(pool)
      leave_types.select { |t| t.pool == pool }.sum { |t| type_total(t) }
    end

    def available_by_pool
      leave_types.group_by(&:pool).transform_values { |types| types.sum { |t| type_total(t) } }
    end

    # Días aprobados aún no gozados a la fecha (R1 "solicitados").
    def requested_days(pool = "vacation")
      -leave_types.select { |t| t.pool == pool }.sum { |t| cell(t, :future) }
    end

    private

    def bucket_for(entry)
      case entry.effective_kind
      when "grant" then :accrued
      when "expiration" then :expired
      when "adjustment" then :adjustments
      when "usage"
        period = entry.leave_period || entry.reverses_entry&.leave_period
        period && period.start_date > as_of ? :future : :taken
      end
    end
  end
end
