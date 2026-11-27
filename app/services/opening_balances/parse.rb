require "csv"
require "digest"

module OpeningBalances
  # R6 (step 1): reads the Excel sheet exported to CSV and builds the diff report.
  # It does not touch the ledger: that only happens when HR approves (Approve).
  # Columns: rut, nombre, legales, progresivas, administrativos, total
  class Parse
    HEADERS = %w[rut nombre legales progresivas administrativos total].freeze
    MAX_LEGAL_ACCUMULATED = 30 # two periods

    def self.call(**) = new(**).call

    def initialize(company:, uploaded_by:, content:, filename:, cutoff_on:)
      @company = company
      @uploaded_by = uploaded_by
      @content = content.to_s.dup.force_encoding("UTF-8").sub("﻿", "")
      @filename = filename
      @cutoff_on = cutoff_on
    end

    def call
      raise Ledger::Error, "Debe indicar la fecha de corte" if @cutoff_on.blank?

      checksum = Digest::SHA256.hexdigest(@content)
      if OpeningBalanceImport.exists?(company: @company, checksum: checksum)
        raise Ledger::Error, "Este archivo ya fue cargado anteriormente"
      end

      csv = CSV.parse(@content, headers: true, header_converters: ->(h) { h.to_s.strip.downcase })
      missing = HEADERS - csv.headers.compact
      raise Ledger::Error, "Faltan columnas: #{missing.join(', ')}" if missing.any?

      ActiveRecord::Base.transaction do
        import = OpeningBalanceImport.create!(
          company: @company, uploaded_by: @uploaded_by, filename: @filename,
          checksum: checksum, cutoff_on: @cutoff_on
        )
        seen = Hash.new(0)
        csv.each.with_index(2) do |row, line| # row 1 = headers
          import.rows.create!(build_row(row, line, seen))
        end
        import
      end
    rescue CSV::MalformedCSVError => e
      raise Ledger::Error, "El archivo no es un CSV válido: #{e.message}"
    end

    private

    def build_row(row, line, seen)
      errors = []
      warnings = []
      rut = row["rut"].to_s.strip.upcase
      seen[rut] += 1
      employee = @company.employees.find_by(rut: rut)

      values = %w[legales progresivas administrativos].index_with do |col|
        parse_number(row[col]).tap { |v| errors << "#{col.capitalize}: valor inválido '#{row[col]}'" if v.nil? }
      end
      total = parse_number(row["total"]) if row["total"].present?
      values.transform_values! { |v| v || 0 }

      errors << "RUT no existe en Buk" unless employee
      errors << "RUT duplicado en el archivo" if seen[rut] > 1
      values.each { |col, v| errors << "#{col.capitalize} negativo" if v.negative? }
      sum = values.values.sum
      if total && total != sum
        errors << "Total del Excel (#{fmt(total)}) no cuadra con la suma (#{fmt(sum)}): diferencia #{fmt(total - sum)}"
      end
      if employee
        errors << "Ingresó después de la fecha de corte" if employee.hire_date > @cutoff_on
        errors << "Ya tiene saldo de apertura migrado" if employee.ledger_opened_on.present?
        if row["nombre"].present? && !similar_name?(row["nombre"], employee.name)
          warnings << "El nombre del Excel ('#{row['nombre']}') no coincide con Buk ('#{employee.name}')"
        end
      end
      if values["legales"] > MAX_LEGAL_ACCUMULATED
        warnings << "Más de dos períodos acumulados (#{fmt(values['legales'])} días legales)"
      end

      {
        row_number: line, rut: rut, employee: employee, employee_name: row["nombre"],
        legal_days: values["legales"], progressive_days: values["progresivas"],
        administrative_days: values["administrativos"], excel_total: total,
        status: errors.any? ? "error" : (warnings.any? ? "warning" : "ok"),
        messages: (errors + warnings).join("\n")
      }
    end

    def parse_number(value)
      return BigDecimal("0") if value.blank?

      BigDecimal(value.to_s.strip.tr(",", "."))
    rescue ArgumentError
      nil
    end

    def similar_name?(a, b)
      normalize = ->(s) { I18n.transliterate(s.to_s).downcase.split }
      (normalize.(a) & normalize.(b)).size >= 2
    end

    def fmt(number) = number.to_s("F").sub(/\.0\z/, "")
  end
end
