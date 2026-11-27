class CreateLeaveGrantsAndPeriods < ActiveRecord::Migration[7.2]
  def change
    # Lotes: cada carga de días. remaining_days es una caché del libro que solo
    # modifican los service objects dentro de la misma transacción que el movimiento.
    create_table :leave_grants do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :leave_type, null: false, foreign_key: true
      t.references :grant_batch, foreign_key: true
      t.string :period
      t.decimal :granted_days, precision: 6, scale: 2, null: false
      t.decimal :remaining_days, precision: 6, scale: 2, null: false
      t.date :granted_on, null: false
      t.date :expires_on
      t.string :source, null: false
      t.timestamps
    end
    add_check_constraint :leave_grants, "remaining_days >= 0", name: "leave_grants_remaining_non_negative"
    add_check_constraint :leave_grants, "granted_days > 0", name: "leave_grants_granted_positive"
    add_check_constraint :leave_grants, "remaining_days <= granted_days", name: "leave_grants_remaining_lte_granted"
    add_index :leave_grants, [:employee_id, :expires_on]

    create_table :leave_periods do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :employees }
      t.string :pool, null: false, default: "vacation"
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :business_days, precision: 6, scale: 2, null: false
      t.datetime :approved_at, null: false
      t.string :status, null: false, default: "requested" # requested | taken | cancelled
      t.string :note
      t.timestamps
    end
    add_check_constraint :leave_periods, "end_date >= start_date", name: "leave_periods_dates_check"
    add_check_constraint :leave_periods, "status IN ('requested','taken','cancelled')", name: "leave_periods_status_check"
    add_index :leave_periods, [:employee_id, :start_date]
  end
end
