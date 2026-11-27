# R6: migración del Excel con trazabilidad por fila y aprobación de RRHH.
class CreateOpeningBalanceImports < ActiveRecord::Migration[7.2]
  def change
    create_table :opening_balance_imports do |t|
      t.references :company, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :employees }
      t.references :approved_by, foreign_key: { to_table: :employees }
      t.string :filename, null: false
      t.string :checksum, null: false
      t.date :cutoff_on, null: false
      t.string :status, null: false, default: "pending" # pending | approved | rejected
      t.datetime :approved_at
      t.timestamps
    end
    add_index :opening_balance_imports, [:company_id, :checksum], unique: true

    create_table :opening_balance_rows do |t|
      t.references :opening_balance_import, null: false, foreign_key: true
      t.references :employee, foreign_key: true
      t.integer :row_number, null: false
      t.string :rut, null: false
      t.string :employee_name
      t.decimal :legal_days, precision: 6, scale: 2, null: false, default: 0
      t.decimal :progressive_days, precision: 6, scale: 2, null: false, default: 0
      t.decimal :administrative_days, precision: 6, scale: 2, null: false, default: 0
      t.decimal :excel_total, precision: 6, scale: 2
      t.string :status, null: false # ok | warning | error
      t.text :messages
      t.timestamps
    end
  end
end
