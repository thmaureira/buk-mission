# employees ya existe en Buk; aquí se modela solo lo que el módulo de vacaciones lee.
class CreateCompaniesAndEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :country, null: false, default: "CL"
      t.timestamps
    end

    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true
      t.references :manager, foreign_key: { to_table: :employees }
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :rut, null: false
      t.string :email
      t.string :area
      t.string :job_title
      # Rol para el POC (autenticación/permisos simplificados): hr | manager | employee
      t.string :role, null: false, default: "employee"
      t.date :hire_date, null: false
      t.integer :prior_service_months, null: false, default: 0
      t.string :prior_service_document_ref
      # Fecha de corte de la migración desde Excel: el job de aniversario solo carga
      # aniversarios posteriores a esta fecha (lo anterior viene en el saldo de apertura).
      t.date :ledger_opened_on
      t.date :terminated_on
      t.timestamps
    end
    add_index :employees, [:company_id, :rut], unique: true
    add_check_constraint :employees, "role IN ('hr','manager','employee')", name: "employees_role_check"
    add_check_constraint :employees, "prior_service_months >= 0", name: "employees_prior_service_check"
  end
end
